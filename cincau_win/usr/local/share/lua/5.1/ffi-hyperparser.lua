--
-- Copyright (c) 2019 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local ffi = require "ffi"

ffi.cdef([[
/* parsing state */
typedef enum {
   PROCESS_STATE_INVALID = 0,   /* not begin, or encouter error */
   PROCESS_STATE_BEGIN = 1,     /* begin message */
   PROCESS_STATE_HEAD = 2,      /* header data comlete */
   PROCESS_STATE_BODY = 3,      /* begin body data */
   PROCESS_STATE_FINISH = 4,    /* message finished */
} http_process_state_t;

/* http header field */
typedef struct s_http_head_kv {
   char *head_field;            /* field name */
   char *head_value;            /* value string */
   struct s_http_head_kv *next;      /* next field */
} http_head_kv_t;

/* http contents */
typedef struct s_http_data {
   unsigned char data[8192]; /* content */
   int data_pos;                        /* partial  */
   struct s_http_data *next;                 /* next block */
} http_data_t;

typedef struct {
   http_process_state_t process_state; /* parsing state */
   const char *method;            /* 'GET', 'POST', ... */
   char url[8192];     /* URL */
   uint16_t status_code;          /* HTTP response */
   http_head_kv_t *head_kv;            /* http header */
   http_data_t *content;               /* http content */
   unsigned int content_length;   /* chunked data cause it 0 */
   unsigned int readed_length;    /* all readed bytes */
   const char *err_msg;           /* error message */
   void *opaque;                  /* reserved for internal use */
} http_ctx_t;

typedef struct {
   unsigned major;
   unsigned minor;
   unsigned patch;
} http_version_t;

/* 0:request 1:response 2:both */
http_ctx_t* mhttp_parser_create(int parser_type);
void mhttp_parser_destroy(http_ctx_t *h);

/* return byte processed, -1 means error */
int mhttp_parser_process(http_ctx_t *h, char *data, int length);

/* in BODY process_state, you can consume data blocks, 
 * minimize the memory usage, and last block may be a 
 * partial one
 */
void mhttp_parser_consume_data(http_ctx_t *h, int count);

/* reset http parser */
void mhttp_parser_reset(http_ctx_t *h);

/* get http version */
void mhttp_parser_version(http_version_t *v);

struct http_parser_url {
  uint16_t field_set;           /* Bitmask of (1 << UF_*) values */
  uint16_t port;                /* Converted UF_PORT string */

  struct {
    uint16_t off;               /* Offset into buffer in which field starts */
    uint16_t len;               /* Length of run in buffer */
  } field_data[7];
};

/* Parse a URL; return nonzero on failure */
int http_parser_parse_url(const char *buf, size_t buflen,
                          int is_connect,
                          struct http_parser_url *u);
]])

-- try to load mnet in package.cpath
local ret, HP = nil, nil
do
    local suffix = jit.os == "Windows" and "dll" or "so"
    for cpath in package.cpath:gmatch("[^;]+") do
        local path = cpath:sub(1, cpath:len() - 2 - suffix:len()) .. "hyperparser." .. suffix
        ret, HP = pcall(ffi.load, path)
        if ret then
            goto SUCCESS_LOAD_LABEL
        end
    end
    error(HP)
    ::SUCCESS_LOAD_LABEL::
end

local type = type
local pairs = pairs
local assert = assert
local tonumber = tonumber
local setmetatable = setmetatable
local sfmt = string.format
local ffi_str = ffi.string
local ffi_copy = ffi.copy

local k_url_len = 8192

local Parser = {
    STATE_HEAD_FINISH = 2,   -- head infomation ready
    STATE_BODY_CONTINUE = 3, -- body infomation on going, chunked exp.
    STATE_BODY_FINISH = 4    -- body infomation ready
}
Parser.__index = Parser

local _intvalue = ffi.new("int", 0)
local _buf = ffi.new("char[?]", k_url_len)

function Parser.version()
    local v = ffi.new("http_version_t")
    HP.mhttp_parser_version(v)
    return sfmt("%d.%d.%d", v.major, v.minor, v.patch)
end

function Parser.createParser(parserType)
    local parser = setmetatable({}, Parser)
    if parserType == "REQUEST" then
        _intvalue = 0
    elseif parserType == "RESPONSE" then
        _intvalue = 1
    else
        _intvalue = 2 -- both
    end
    parser._hp = HP.mhttp_parser_create(_intvalue)
    parser._state = -1
    parser._htbl = {}
    parser._data = ""
    return parser
end

function Parser:destroy()
    if self._hp ~= nil then
        HP.mhttp_parser_destroy(self._hp)
        self._hp = nil
        self._state = -1
        self._data = ""
        for k, _ in pairs(self._htbl) do
            self._htbl[k] = nil
        end
    end
end

-- reset parser, ready for next parse
function Parser:reset()
    self._state = -1
    self._data = ""
    for k, _ in pairs(self._htbl) do
        self._htbl[k] = nil
    end
end

local function _unpack_http(_hp, htbl)
    local method = ffi_str(_hp.method)
    if not method:find("<") then
        htbl.method = method
    end
    local status_code = tonumber(_hp.status_code)
    if status_code > 0 and status_code < 65535 then
        htbl.status_code = status_code
    end
    local content_length = tonumber(_hp.content_length)
    if content_length > 0 then
        htbl.content_length = content_length
    end
    htbl.readed_length = tonumber(_hp.readed_length)
    local url = ffi_str(_hp.url)
    if url:len() > 0 then
        htbl.url = url
    end
    if _hp.head_kv ~= nil and htbl.header == nil then
        htbl.header = {}
        local kv = _hp.head_kv
        while kv ~= nil do
            local field = kv.head_field
            local value = kv.head_value ~= nil and ffi_str(kv.head_value) or ""
            if field ~= nil then
                htbl.header[ffi_str(field)] = value
            else
                htbl.header[#htbl.header + 1] = value
            end
            kv = kv.next
        end
    end
    if _hp.content ~= nil then
        htbl.contents = htbl.contents or {}
        local data_count = 0
        local c = _hp.content
        while c ~= nil do
            data_count = data_count + 1
            htbl.contents[#htbl.contents + 1] = ffi_str(c.data, c.data_pos)
            c = c.next
        end
        HP.mhttp_parser_consume_data(_hp, data_count) -- consume data count from parser
    end
    if _hp.err_msg ~= nil then
        htbl.err_msg = ffi_str(_hp.err_msg)
    end
    return htbl
end

-- process input data, and holding left, only input new data
-- return nread, state, http_info_table
function Parser:process(data)
    assert(type(data) == "string", "invalid data type")
    local nread = 0
    local state = nil
    data = self._data .. data
    repeat
        _intvalue = data:len() < k_url_len and data:len() or k_url_len
        ffi_copy(_buf, data, _intvalue)
        local count = tonumber(HP.mhttp_parser_process(self._hp, _buf, _intvalue))
	    nread = nread + count
        state = tonumber(self._hp.process_state)
        if self._state ~= state then
            if state == HP.PROCESS_STATE_HEAD then
                self._htbl = _unpack_http(self._hp, self._htbl)
            elseif state == HP.PROCESS_STATE_BODY then
                self._htbl = _unpack_http(self._hp, self._htbl)
            elseif state == HP.PROCESS_STATE_FINISH then
                self._htbl = _unpack_http(self._hp, self._htbl)
                HP.mhttp_parser_reset(self._hp) -- reset when finish
            end
            self._state = state
        end
        data = data:len() > count and data:sub(count + 1) or ""
    until count <= 0 or data:len() <= 0
    self._data = data
    return nread, self._state, self._htbl
end

function Parser.parseURL(url, is_connect)
    local tbl = {}
    if type(url) ~= "string" or url:len() <= 0 then
        return tbl
    end
    local ctx = ffi.new("struct http_parser_url")
    HP.http_parser_parse_url(url, url:len(), is_connect and 1 or 0, ctx)
    local fdata = ctx.field_data
    local kv = { "schema", "host", "port", "path", "query", "fragment", "userinfo", "max" }
    for i=0, 6 do
        local len = fdata[i].len
        if len > 0 then
            local s = fdata[i].off + 1
            tbl[kv[i+1]] = url:sub(s, s + len - 1)
        end
    end
    return tbl
end

return Parser
