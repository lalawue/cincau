--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local ffi = require("ffi")

ffi.cdef [[
/* -- Build query content
 * buf: buffer for store DNS query packet content, must have size == 1024 bytes
 * qid: DNS query id, make sure > 0
 * domain: '0' terminated string
 * --
 * return: 0 for error, or valid query_size > 0
 */
 int mdns_query_build(uint8_t *buf, unsigned short qid, const char *domain);

 /* -- fetch query id for later input query_size
  * buf: response buffer, must have size == 1024 byte
  * content_len: valid content length
  * --
  * return: 0 for error, or qid from response
  */
 int mdns_response_fetch_qid(const uint8_t *buf, int content_len);
 
 /* -- 
  * buf: response buffer, must have size == 1024 byte
  * content_len: valid content length
  * query_size: query_size for qid fetched before
  * domain: '0' terminated string for compare
  * out_ipv4: 4 byte buffer for output ipv4
  * --
  * return: 0 for error, 1 for ok
  */
 int mdns_response_parse(uint8_t *buf,
                         int content_len,
                         int query_size,
                         const char *domain,
                         uint8_t *out_ipv4);
]]

local DnsCore = ffi.load("mdns_utils")
local NetCore = require("ffi_mnet")
local UrlCore = require("base.url_core")
local AvlTree = require("base.avl")

local _M = {}
_M.__index = {}

function _M:_initialize()
    self._svr_tbl = {}
    -- wait processing list as { qid, domain, query_size }
    self._qid_avl =
        AvlTree.new(
        function(a, b)
            return a.qid - b.qid
        end
    )
    -- result table domain to ipv4 string
    self._domain_tbl = {}
    -- wait response list
    self._wait_tbl = {}
    math.randomseed(os.time())
end

--
-- Internal
--

-- UDP DNS Query
function _M:_initUdpQueryChanns()
    local dns_ipv4 = {
        "114.114.114.114",
        "8.8.8.8"
    }
    for i = 1, #dns_ipv4, 1 do
        local udp_chann = NetCore.openChann("udp")
        udp_chann:setCallback(
            function(chann, event_name, _, _)
                if event_name == "event_recv" then
                    self:_processResponse(chann:recv())
                end
            end
        )
        udp_chann:connect(dns_ipv4[i], 53)
        self._svr_tbl[#self._svr_tbl + 1] = udp_chann
    end
end

local _copy = ffi.copy
local _fill = ffi.fill
local _string = ffi.string

local _buf = ffi.new("uint8_t[?]", 1024)
local _domain = ffi.new("uint8_t[?]", 256)
local _out_ipv4 = ffi.new("uint8_t[?]", 4)

function _M:_processRequest(domain, callback)
    if type(domain) ~= "string" then
        return false
    end
    local ipv4 = self._domain_tbl[domain]
    if ipv4 then
        callback(ipv4)
    else
        -- build UDP package
        local qid = math.random(65535)
        _fill(_domain, 256)
        _copy(_domain, domain)
        local query_size = DnsCore.mdns_query_build(_buf, qid, _domain)
        if query_size <= 0 then
            return false
        end
        local item = {qid = qid, domain = domain, query_size = query_size}
        self._qid_avl:insert(item)
        local data = _string(_buf, query_size)
        for _, chann in ipairs(self._svr_tbl) do
            chann:send(data)
        end
        -- add response to wait list
        if not self._wait_tbl[domain] then
            self._wait_tbl[domain] = {}
        end
        local tbl = self._wait_tbl[domain]
        tbl[#tbl + 1] = callback
    end
    return true
end

function _M:_processResponse(pkg_data)
    if pkg_data == nil then
        return
    end
    -- check response
    _copy(_buf, pkg_data, pkg_data:len())
    local qid = DnsCore.mdns_response_fetch_qid(_buf, pkg_data:len())
    local item = self._qid_avl:find({qid = qid})
    if not item then
        return
    end
    _fill(_domain, 256)
    _copy(_domain, item.domain)
    local ret = DnsCore.mdns_response_parse(_buf, pkg_data:len(), item.query_size, _domain, _out_ipv4)
    if ret <= 0 then
        self:_rpcResponse(item.domain, nil)
        return
    end
    local out = _string(_out_ipv4, 4)
    local ipv4 = string.format("%d.%d.%d.%d", out:byte(1), out:byte(2), out:byte(3), out:byte(4))
    self._domain_tbl[item.domain] = ipv4
    -- process wait response
    self:_rpcResponse(item.domain, ipv4)
    -- remove from wait processing list
    self._qid_avl:remove(item)
end

function _M:_rpcResponse(domain, data)
    local tbl = self._wait_tbl[domain]
    if tbl then
        for _, callback in ipairs(tbl) do
            callback(data)
        end
        self._wait_tbl[domain] = nil
    end
end

-- public interface
--

-- init after mnet init
local function _init(config)
    _M:_initialize()
    _M:_initUdpQueryChanns()
end

-- callback(ipv4)
local function _queryHost(host, callback)
    if type(host) ~= "string" or not callback then
        return false
    end
    return _M:_processRequest(host, callback)
end

return {
    init = _init,
    queryHost = _queryHost
}
