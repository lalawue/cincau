--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

-- this module only for mnet
--

local ThreaBroker = require("bridge.thread_broker")
local _engine_valid = require("config").engine_type == "mnet"
local DnsCore = _engine_valid and require("bridge.ffi_mdns") or {}
local Browser = _engine_valid and require("bridge.http_browser")

local _M = {
    _callbacks = setmetatable({}, {__mode = "k"})
}

-- in server loop
function _M.servLoop()
    for key, fn in pairs(_M._callbacks) do
        if fn.check_stop() then
            _M._callbacks[key] = nil
            if fn.finalizer then
                fn.finalizer()
            end
            break
        end
    end
end

-- check_stop return true to finish loop, and run finalizer in the end
local function _addServLoopCallback(key, check_stop, finalizer)
    if key and type(check_stop) == "function" then
        _M._callbacks[key] = {check_stop = check_stop, finalizer = finalizer}
    end
end

-- query domain's ipv4, return ipv4
function _M.queryDomain(domain)
    if not _engine_valid then
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
        header = {} -- header option, not implement yet
        recv_cb = function(header_tbl, data_string) end, -- for receiving data
    }
    return header_tbl, data_string (if no recv_cb function set)
]]
local function _dummy_cb()
end
function _M.requestURL(url, option)
    if not _engine_valid then
        return ""
    end
    if type(url) ~= "string" then
        return nil
    end
    print(option, option and option.recv_cb)
    return ThreaBroker.callThread(
        function(ret_func)
            local data_tbl = {}
            local recv_cb = option and option.recv_cb or _dummy_cb
            local url_opt = option or {}
            url_opt.recv_cb = function(header_tbl, data_str)
                if header_tbl == nil then
                    ret_func()
                elseif data_str then
                    recv_cb(header_tbl, data_str)
                    data_tbl[#data_tbl + 1] = data_str
                else
                    recv_cb(header_tbl, nil)
                    ret_func(header_tbl, table.concat(data_tbl))
                end
            end
            local brw = Browser.newBrowser()
            brw:requestURL(url, url_opt)
            _addServLoopCallback(
                brw,
                function()
                    return brw:onLoopEvent()
                end,
                nil
            )
        end
    )
end

return _M
