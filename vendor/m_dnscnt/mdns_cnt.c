/* 
 * Copyright (c) 2018 lalawue
 * 
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the MIT license. See LICENSE for details.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "plat_os.h"

#if PLAT_OS_WIN
#include <Winsock2.h>
#else
#include <arpa/inet.h>
#endif

#include "m_mem.h"
#include "m_list.h"
#include "m_prng.h"
#include "m_skiplist.h"
#include "plat_time.h"
#include "mdns_cnt.h"
#include "mnet_core.h"

static const int64_t k_expired_time_micro_seconds = MTIME_MICRO_PER_SEC * (int64_t)MDNS_IP_EXPIRED_SECOND;

/* structures for DNS query
 */

typedef struct {
   unsigned short id;            // identification number

   /** flags in a diferent order than in DNS RFC, because of the
       network byte order (big-endian) ; locally it's
       little-endian ; and that contains bitfields, they are
       put from the least significant bit of the least
       significant byte.
   */
   unsigned short
      rd: 1,                    // recursion desired
      tc: 1,                    // truncated message
      aa: 1,                    // authoritive answer
      opcode: 4,                // purpose of message 
      qr: 1,                    // query/response flag
      rcode: 4,                 // response code
      z: 3,
      ra: 1;                    // recursion available
    
   unsigned short qdcount;
   unsigned short ancount;
   unsigned short nscount;
   unsigned short arcount;
} dns_header_t;

typedef struct {
   unsigned short qtype;
   unsigned short qclass;
} dns_question_t;

typedef struct {
   unsigned short type; //two octets containing one of the RR TYPE codes
   unsigned short _class;
   unsigned int ttl;
   unsigned int rdlen:16;      // length of rdata
   unsigned int none:16;       // for pading, need to remove when sizeof
} dns_rr_data_t;

/* the real size for rr data */
static inline int
_sizeof_dns_rr_data(void) {
   return sizeof(dns_rr_data_t) - 2;
}

/* 
 */

#define DNS_SVR_PORT 53
#define CNT_BUF_LEN (2048)

typedef struct {
   char domain[MDNS_QUERY_DOMAIN_LEN]; /* format: 3www6domain3com */
   unsigned char dlen;                 /* doman_len */
   unsigned int dhash;                 /* hash for domain */
   unsigned short qid;                 /* dns query id */
   unsigned short query_size;          /* query size */
   char *err_msg;                      /* error message */
   int64_t query_ti;
} query_item_t;

typedef struct {
   char domain[MDNS_QUERY_DOMAIN_LEN];
   unsigned char dlen;
   unsigned int dhash;
   unsigned char ipv4[4];
   int64_t response_ti;         /* response time */
} result_item_t;

/* program context */
typedef struct {
   prng_t prng;                 /* for random number */
   unsigned char *buf;          /* buffer */
   lst_t *udp_lst;              /* client list */
   skt_t *query_skt;            /* query in progress, key is qid */
   skt_t *domain_skt;           /* query in progress, key is dhash */
   skt_t *result_skt;           /* result item */
   int64_t last_ti;             /* check result_item  */
   mdns_result_t result;
} mdns_t;


static inline mdns_t*
_mdns(void) {
   static mdns_t dns;
   return &dns;
}

static inline unsigned short
_mdns_random_qid(void) {
   return htons(prng_next(&_mdns()->prng));
}

static inline query_item_t*
_mdns_item_from_qid(unsigned short qid) {
   return (query_item_t*)skt_query(_mdns()->query_skt, qid);
}

static void
_mdns_result_insert_item(query_item_t *item, unsigned char *ipv4) {
   mdns_t *md = _mdns();
   result_item_t *result = (result_item_t*)mm_malloc(sizeof(*result));
   memcpy(result->domain, item->domain, item->dlen);
   memcpy(result->ipv4, ipv4, 4);
   result->dlen = item->dlen;
   result->dhash = item->dhash;
   result->response_ti = md->last_ti;
   skt_insert(md->result_skt, item->dhash, result);
}

static void
_mdns_result_remove_item(result_item_t *result) {
   skt_remove(_mdns()->result_skt, result->dhash);
   mm_free(result);
}

static result_item_t*
_mdns_result_query_item(query_item_t *item) {
   result_item_t *result = (result_item_t*)skt_query(_mdns()->result_skt, item->dhash);
   if (result) {
      if (result->dlen == item->dlen &&
          memcmp(result->domain, item->domain, item->dlen)==0)
      {
         return result;
      }
   }      
   return 0;
}

/* check response header part */
static int
_response_check_header(query_item_t *item,  unsigned char *buf, int data_len) {
   if (item && buf && data_len>0) {
      const dns_header_t *rh = (dns_header_t*)buf;
      const int code = rh->rcode;
   
      if ((rh->id != item->qid) ||
          (rh->qr != 1) ||
          (rh->opcode != 0) ||
          (rh->rd != 1) ||
          (rh->z != 0) ||
          (rh->qdcount != htons(1)) ||
          (rh->ancount == 0 && code == 0) ||
          (code >= 6 && code <= 15))
      {
         item->err_msg = "unexpected DNS header";
         return 0;
      }

      switch (code) {
         case 1: item->err_msg = "DNS query format error"; return 0;
         case 2: item->err_msg = "internal DNS server failure"; return 0;
         case 3: item->err_msg = "domain name doesn't exist"; return 0;
         case 4: item->err_msg = "type of query not supported by DNS server"; return 0;
         case 5: item->err_msg = "requested operation refused by DNS server"; return 0;
      }

      return 1;
   }
   return 0;
}

/* check response question part */
static int
_response_check_question(query_item_t *item, unsigned char *buf, int data_len) {
   char *rqname = (char*)&buf[sizeof(dns_header_t)];
   dns_question_t *rq = (dns_question_t*)&buf[item->query_size - sizeof(dns_question_t)];

   if (strncmp(rqname, item->domain, item->dlen) ||
       !(rq->qtype==0 && rq->qclass==htons(1)))
   {
      item->err_msg = "unexpected question section";
   }
   
   return 1;
}

/* fetch rr_data from response, output ipv4 */
static int
_response_fetch_res(query_item_t *item, unsigned char *ipv4, unsigned char *buf, int data_len) {
   dns_header_t *rh = (dns_header_t*)buf;
   int aname_size = 0;   
   char *rsp_aname = NULL;
   dns_rr_data_t *rsp_answer = NULL;

   int prev_size = item->query_size;
   
   for (int i=0; i<ntohs(rh->ancount); i++) {
      //printf("prev_size: %d\n", prev_size);
       
      if (data_len <= (prev_size + 2 + (int)sizeof(dns_header_t))) {
         item->err_msg = "incomplete DNS response 0";
         return 0;
      }

      rsp_aname = (char*)&buf[prev_size];
      //printf("rsp name %d\n", (int)strlen(rsp_aname));      

      if ((aname_size = strlen(rsp_aname)) < 2 ||
          data_len <= (prev_size + aname_size + _sizeof_dns_rr_data()))
      {
         //printf("aname_size %d\n", aname_size);
         item->err_msg = "incomplete DNS response 1";
         return 0;
      }

      rsp_answer = (dns_rr_data_t*)&buf[prev_size + aname_size];

      if (data_len < (prev_size +
                      aname_size +
                      _sizeof_dns_rr_data() +
                      ntohs(rsp_answer->rdlen)))
      {
         item->err_msg = "incomplete DNS response 2";
         return 0;
      }

      const unsigned short v1 = ntohs(1);
      if (rsp_answer->_class == v1 &&
          (rsp_answer->type == v1 || rsp_answer->type==ntohs(12)))
      {
         int offset = prev_size + aname_size + _sizeof_dns_rr_data();
         unsigned char *result = (unsigned char*)&buf[offset];
         memcpy(ipv4, result, 4);
         return 1;
      }

      prev_size = prev_size + aname_size + _sizeof_dns_rr_data() + ntohs(rsp_answer->rdlen);
   }

   item->err_msg = "unable to find IP record";
   return 0;
}

static query_item_t*
_qitem_create(query_item_t *item) {
   query_item_t *pitem = (query_item_t*)mm_malloc(sizeof(*item));
   memcpy(pitem, item, sizeof(*item));
   return pitem;
}

static void
_qitem_destroy(query_item_t *item) {
   mm_free(item);
}

/* udp response */
static int
_chann_response(chann_msg_t *msg) {
   int ret = 0;
   if (msg->event == CHANN_EVENT_RECV) {
      mdns_t *md = _mdns();      
      chann_t *udp = msg->n;
      unsigned char *buf = md->buf;
      
      memset(buf, 0, CNT_BUF_LEN);
      const rw_result_t *rw = mnet_chann_recv(udp, buf, CNT_BUF_LEN);

      if (rw->ret > 0) {
         unsigned char ipv4[4];
         
         const dns_header_t *rh = (dns_header_t*)buf;
         query_item_t *item = _mdns_item_from_qid(rh->id);

         if (item) {
            if (_response_check_header(item, buf, rw->ret) &&
                _response_check_question(item, buf, rw->ret) &&
                _response_fetch_res(item, ipv4, buf, rw->ret))
            {
               _mdns_result_insert_item(item, ipv4);
               ret = 1;
            }

            skt_remove(md->query_skt, item->qid);
            skt_remove(md->domain_skt, item->dhash);
            _qitem_destroy(item);
         }
      }
   }
   return ret;
}

/* validate label length */
static inline int
_get_label_len(query_item_t *item, int pos, int llen) {
   if (llen>63 || llen<=0) {
      item->err_msg = "invalid label length";
      return 0;
   }
   item->domain[pos] = llen;
   return 1;
}

/* build query item from domain, validate it */
static int
_build_query_item(query_item_t *item, const char *domain, int domain_len) {
   if (item==NULL || domain==NULL || domain_len<=0) {
      item->err_msg = "param error";
      return 0;
   }

   memset(item, 0, sizeof(*item));
   item->domain[0] = '.';
   
   int i=0, j=0, dot=0;
   for (; i<domain_len && domain[i] && i<MDNS_QUERY_DOMAIN_LEN; i++) {
      
      item->dhash += 256 - i + (i+1) * ((unsigned char*)domain)[i];
      
      if (domain[i] == '.') {
         if ( !_get_label_len(item, j, i - j) ) {
            return 0;
         }
         j = 1 + i;
         dot += 1;
      } else {
         item->domain[1 + i] = domain[i];
      }
   }
   
   if ( !_get_label_len(item, j, i - j) ) {
      return 0;
   }
   
   item->dlen = 1 + i;
   
   if (dot<1 || i>255) {
      item->err_msg = "invalid domain";
      return 0;
   }

   return 1;
}

/* build UDP query packet in buffer from query item */
static void
_build_udp_request(unsigned char *buf, query_item_t *item) {
   item->query_size = sizeof(dns_header_t) + item->dlen + 1 + sizeof(dns_question_t);
   item->qid = _mdns_random_qid();   

   memset(buf, 0, CNT_BUF_LEN);

   dns_header_t *h =  (dns_header_t*)buf;
   h->id = item->qid;
   h->qr = 0;                   /* this is a query */
   h->opcode = 0;               /* this is a standard query */
   h->aa = 0;                   /* NOT Authoritative */
   h->tc = 0;                   /* not truncated */
   h->rd = 1;                   /* Recursion Desired */
   h->ra = 0;                   /* Recursion not available */
   h->z = 0;
   h->rcode = 0;
   
   h->qdcount = htons(1);
   h->ancount  = 0;
   h->nscount = 0;
   h->arcount  = 0;
   
   /* fill qname */
   char *qname = (char*)&buf[sizeof(dns_header_t)];
   memcpy(qname, item->domain, item->dlen);
   
   dns_question_t *q = (dns_question_t*)&buf[sizeof(dns_header_t) + item->dlen + 1];
   q->qtype = htons(1);         /* IPv4 */
   q->qclass = htons(1);        /* internet */
}

/* is domain in query progress, key is dhash */
static query_item_t*
_domain_is_in_progress(query_item_t *item) {
   query_item_t *pitem = (query_item_t*)skt_query(_mdns()->domain_skt, item->dhash);
   if (pitem &&
       (pitem->dlen == item->dlen) &&
       (memcmp(pitem->domain, item->domain, pitem->dlen) == 0))
   {
      return pitem;
   }
   return NULL;
}

static int
_cnt_send_request(chann_t *udp, unsigned char *buf, query_item_t *item) {
   rw_result_t *rw = mnet_chann_send(udp, buf, item->query_size);
   if (rw->ret > 0) {
      item->query_ti = _mdns()->last_ti;
      return 1;
   } else {
      item->err_msg = "cnt error, fail to send data";
      return 0;
   }
}

/* craete DNS query packet, post to every DNS server */
static int
_cnt_dispatch(query_item_t *item) {
   mdns_t *md = _mdns();

   _build_udp_request( md->buf, item );

   int sended = 0;
   
   lst_foreach(it, md->udp_lst) {
      chann_t *udp = (chann_t *)lst_iter_data(it);

      if ( _cnt_send_request( udp, md->buf, item ) ) {
         sended = 1;
      }
   }

   if (sended) {
      skt_insert(md->query_skt, item->qid, item);
      skt_insert(md->domain_skt, item->dhash, item);
   } else {
      _qitem_destroy(item);
   }

   return sended;
}


/* Public Interface
 */

int
mdns_init(void *udp_chann_array, int count) {
   if (udp_chann_array && (count > 0)) {
      mdns_t *md = _mdns();
      if ( !md->udp_lst ) {
         prng_init(&md->prng);

         md->buf = (unsigned char*)mm_malloc(CNT_BUF_LEN);
         md->udp_lst = lst_create();
         md->query_skt = skt_create();
         md->domain_skt = skt_create();
         md->result_skt = skt_create();

         chann_t **chann_list = (chann_t**)udp_chann_array;
         for (int i=0; i<count; i++) {
            lst_pushl(md->udp_lst, chann_list[i]);
         }
         return 1;
      }
   }
   return 0;
}

void
mdns_fini(void) {
   mdns_t *md = _mdns();   
   if (lst_count(md->udp_lst) > 0) {
      while (lst_count(md->udp_lst) > 0) {
         mnet_chann_close((chann_t *)lst_popf(md->udp_lst));
      }
      while (skt_count(md->query_skt) > 0) {
         _qitem_destroy((query_item_t*)skt_popf(md->query_skt));
      }
      while (skt_count(md->domain_skt) > 0) {
         skt_popf(md->domain_skt); /* free in query_skt */
      }
      while (skt_count(md->result_skt) > 0) {
         mm_free(skt_popf(md->result_skt));
      }
      lst_destroy(md->udp_lst);
      skt_destroy(md->query_skt);
      skt_destroy(md->domain_skt);
      skt_destroy(md->result_skt);
      mm_free(md->buf);

      memset(md, 0, sizeof(*md));
   }
}

int
mdns_store(void *msg_data) {
   int ret = 0;
   chann_msg_t *msg = msg_data;
   while (msg) {
      if (_chann_response(msg)) {
         ret = 1;
      }
      msg = msg->opaque;
   }
   return ret;
}



/* construct query item, check cached first, otherwise query server */
mdns_result_t*
mdns_query(const char *domain, int domain_len) {
   mdns_t *md = _mdns();
   if (!domain || domain_len<=0) {
      md->result.err_msg = "Invalid params";
      md->result.state = MDNS_STATE_INVALID;
      return &md->result;
   }
   
   query_item_t item;
   if ( !_build_query_item(&item, domain, domain_len) ) {
      md->result.err_msg= item.err_msg;
      md->result.state = MDNS_STATE_INVALID;
      return &md->result;
   }

   // update last ti
   md->last_ti = mtime_current();
         
   result_item_t *result = _mdns_result_query_item(&item);
   do {
      if ( !result ) {
         query_item_t *pitem = _domain_is_in_progress(&item);
         if ( pitem ) {
            // if query in the progress
            md->result.state = MDNS_STATE_INPROGRESS;
         } else {
            // start new query
            pitem = _qitem_create(&item);
            _cnt_dispatch(pitem);
            md->result.state = MDNS_STATE_INPROGRESS;
         }
         break;
      } else if ((md->last_ti - result->response_ti) > k_expired_time_micro_seconds) {
         // if result expired
         _mdns_result_remove_item(result);
         result = NULL;
      } else {
         memcpy(md->result.ipv4, result->ipv4, 4);
         md->result.state = MDNS_STATE_SUCCESS;
      }
   } while ( !result );
   md->result.err_msg = NULL;
   return &md->result;
}

/* cleanup DNS query timeout */
void
mdns_cleanup(int timeout_ms) {
   mdns_t *md = _mdns();
   md->last_ti = mtime_current();

   // remove query item when timeout
   skt_foreach(it, md->query_skt) {
      query_item_t *item = (query_item_t*)it->value;
      
      if ((md->last_ti - item->query_ti) > (int64_t)timeout_ms) {
         
         //_qitem_notify(item, NULL, "query timeout");
         
         skt_iter_remove(md->query_skt, it);
         skt_remove(md->domain_skt, item->dhash);
         _qitem_destroy(item);
      }
   }
}

const char*
mdns_addr(unsigned char *ipv4) {
   static char addr[17];
   for (int i=0; i<4; i++) {
      sprintf(addr, "%d.%d.%d.%d", ipv4[0], ipv4[1], ipv4[2], ipv4[3]);
   }
   return addr;
}

#ifdef MDNS_STANDALONE_MODE
int
main(int argc, char *argv[])
{
   if (argc < 2) {
      printf("%s DOMAIN\n", argv[0]);
      return 0;
   }

   mnet_init(1);

   const char *dns_servers[] = {
      "8.8.8.8",
      "8.8.4.4",
      NULL,
   };
   chann_t *chann_list[2] = {0, 0};
   for (int i=0; i<2; i++) {
      chann_t *n = mnet_chann_open(CHANN_TYPE_DGRAM);
      mnet_chann_connect(n, dns_servers[i], DNS_SVR_PORT);
      chann_list[i] = n;
   }

   mdns_init(chann_list, 2);

   mdns_result_t *query = mdns_query(argv[1], strlen(argv[1]));
   
   for (;;) {
      poll_result_t *result = mnet_poll(1000000);
      chann_msg_t *msg = mnet_result_next(result);
      if (msg && mdns_store(msg)) {
         query = mdns_query(argv[1], strlen(argv[1]));
         if (query->state == MDNS_STATE_SUCCESS) {
            printf("%s\n", mdns_addr(query->ipv4));
            break;
         }
      }
   }

   mnet_fini();
   
   return 0;
}
#endif
