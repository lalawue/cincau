--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local ffi = require("ffi")

ffi.cdef [[
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

// pull-style api mnet_init(1), input udp chann_t array with count
int mdns_init(void *udp_chann_array, int count);
void mdns_fini(void);

// recv chann_msg_t data, , return 1 for got ip
int mdns_store(void *chann_msg_t);

// send data to udp   
mdns_result_t* mdns_query(const char *domain, int domain_len);

// convert ipv4[4] to string ip max 16 bytes
const char* mdns_addr(unsigned char *ipv4);

// clean oudated ip   
void mdns_cleanup(int timeout_ms);
]]

local DnsCore = ffi.load("mdns")
local NetCore = require("ffi_mnet")

-- internal interface
--

local _result = ffi.new("mdns_result_t *")

-- raise UDP DNS query
local function _queryFromDnsCore(host)
    local dn = ffi.new("char[?]", host:len() + 1)
    ffi.copy(dn, host, host:len())
    _result = DnsCore.mdns_query(dn, host:len())
    if _result.state == DnsCore.MDNS_STATE_INVALID then
        return false, _result.err_msg
    elseif _result.state == DnsCore.MDNS_STATE_INPROGRESS then
        return false, nil
    else
        local ipv4 = ffi.string(DnsCore.mdns_addr(_result.ipv4))
        return true, ipv4
    end
end

-- if query in process, add next query from main entry
local function _waitListAdd(M, host, callback)
    if M._wait_list[host] == nil then
        M._wait_count = M._wait_count + 1
        M._wait_list[host] = callback
    end
end

-- C level holding host <-> ipv4 pair, remove from waiting list
local function _waitListRemove(M, host)
    if M._wait_list[host] ~= nil then
        M._wait_count = M._wait_count - 1
        M._wait_list[host] = nil
    end
end

-- C level return host <-> ipv4 pair, process pair here
local function _waitListProcess(M)
    if M._wait_count <= 0 then
        return
    end
    local del_tbl = {}
    for host, callback in pairs(M._wait_list) do
        local ret, ipv4 = _queryFromDnsCore(host)
        if ret and ipv4 then
            callback(ipv4)
            del_tbl[#del_tbl + 1] = host
        end
    end
    for _, host in ipairs(del_tbl) do
        _waitListRemove(M, host)
    end
end

-- init udp for query DNS
local function _initBusiness(M)
    local dns_ipv4 = {
        "114.114.114.114",
        "8.8.8.8"
    }
    local c_udp_channs = ffi.new("chann_t*[?]", #dns_ipv4)
    for i = 1, 2 do
        local udp_chann = NetCore.openChann("udp")
        udp_chann:setCallback(
            function(_, event_name, _, c_msg)
                if event_name == "event_recv" then
                    DnsCore.mdns_store(c_msg)
                    _waitListProcess(M) -- check and an continue callback
                end
            end
        )
        udp_chann:connect(dns_ipv4[i], 53)
        c_udp_channs[i - 1] = udp_chann.m_chann
    end
    -- set C UDP chann to DnsCore
    DnsCore.mdns_init(c_udp_channs, #dns_ipv4)
end

-- public interface
--

local _M = {}
_M.__index = _M

-- init after mnet init
function _M.init(config)
    if not _M._has_init then
        _M._has_init = true
        _M._config = config
        _M._wait_count = 0
        _M._wait_list = {}
        _initBusiness(_M)
    end
end

-- callback(ipv4)
function _M.queryHost(host, callback)
    if type(host) ~= "string" or not callback then
        return false
    end
    local ret, ipv4 = _queryFromDnsCore(host)
    if ret and ipv4 then
        callback(ipv4)
    else
        _waitListAdd(_M, host, callback)
    end
    return true
end

return _M
