--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

-- this module only for mnet
--

local ThreaBroker = require("bridge.thread_broker")
local CurlCore = require("lcurl")
local _valid = require("config").engine_type == "mnet"
local DnsCore = _valid and require("bridge.ffi_mdns") or {}

local _M = {}

-- query domain's ipv4, return ipv4
function _M.queryDomain(domain)
    if not _valid then
        return ""
    end
    return ThreaBroker.callThread(
        function(ret_func)
            DnsCore.queryHost(
                domain,
                function(ipv4)
                    ret_func(ipv4)
                end
            )
        end
    )
end

--[[
    request HTTP/HTTPS URL
    option = {
        header = {...},
        callback = function(header_tbl, data_string) end,
    }
    return header_tbl, data_string (if no callback function set)
]]
local _dummy_option = {}
function _M.requestURL(url, option)
    if type(url) ~= "string" then
        return nil
    end
    option = option or _dummy_option
    local op =
        CurlCore.easy {
        url = url,
        httpheader = option.header
    }
    local header_tbl = {}
    local data_tbl = {}
    op:setopt_headerfunction(table.insert, header_tbl)
    if option.callback then
        op:setopt_writefunction(option.callback, header_tbl)
    else
        op:setopt_writefunction(table.insert, data_tbl)
    end
    op:perform()
    op:close()
    return header_tbl, table.concat(data_tbl)
end

return _M
