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
local CurlCore = _engine_valid and require("lcurl") or {}
local DnsCore = _engine_valid and require("bridge.ffi_mdns") or {}

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

-- func return false to finish loop, and run finalizer in the end
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

local _dummy_option = {}

--[[
    request HTTP/HTTPS URL
    option = {
        reciever = function(header_tbl, data_string) end, -- for receiving data
    }
    return header_tbl, data_string (if no reciever function set)
]]
function _M.requestURL(url, option)
    if not _engine_valid then
        return ""
    end
    if type(url) ~= "string" then
        return nil
    end
    option = option or _dummy_option
    local easy =
        CurlCore.easy {
        url = url,
        httpheader = option.header
    }
    local header_tbl = {}
    local data_tbl = {}
    easy:setopt_headerfunction(table.insert, header_tbl)
    if option.reciever then
        easy:setopt_writefunction(option.reciever, header_tbl)
    else
        easy:setopt_writefunction(table.insert, data_tbl)
    end
    if not _M._multi then
        _M._multi = CurlCore.multi()
    end
    _M._multi:add_handle(easy)
    local co = coroutine.running()
    _addServLoopCallback(
        easy,
        function()
            if _M._multi:perform() > 0 then
                _M._multi:wait(0)
            else
                return true
            end
        end,
        function()
            _M._multi:remove_handle(easy)
            easy:close()
            coroutine.resume(co, header_tbl, table.concat(data_tbl))
        end
    )
    return coroutine.yield()
end

return _M
