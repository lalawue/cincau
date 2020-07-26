/* 
 * Copyright (c) 2018 lalawue
 * 
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the MIT license. See LICENSE for details.
 */

#ifndef MDNS_CNT_H
#define MDNS_CNT_H

#define MDNS_QUERY_DOMAIN_LEN  256
#define MDNS_IP_EXPIRED_SECOND 172800 /* 2 day, 3600*24*2 */

typedef enum {
   MDNS_STATE_INVALID = 0,
   MDNS_STATE_INPROGRESS,
   MDNS_STATE_SUCCESS,
} mdns_state_t;

typedef struct {
   unsigned char ipv4[4];       /* ip */
   mdns_state_t state;          /* pull-style api */
   char *err_msg;               /* error message */
} mdns_result_t;

#ifdef __cplusplus
extern "C" {
#endif

// pull-style api mnet_init(1), input udp chann_t array with count
int mdns_init(void *udp_chann_array, int count);
void mdns_fini(void);

// recv chann_msg_t data, , return 1 for got ip
int mdns_store(void *chann_msg_t);

// query database, or query from DNS server
mdns_result_t* mdns_query(const char *domain, int domain_len);

// convert ipv4[4] to string ip up 16 bytes max
const char* mdns_addr(unsigned char *ipv4);

// clean oudated ip   
void mdns_cleanup(int timeout_ms);

#ifdef __cplusplus
}
#endif

#endif
