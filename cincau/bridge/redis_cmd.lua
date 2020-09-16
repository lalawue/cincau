--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local NetCore = require("ffi_mnet")
local Resp = require("resp")

local _M = {}

--[[
    cmd_tbl should be { "SET", "KEY", "VALUE" },
    ret_func should be function(ret_value), ret_value = nil means server side disconnect
]]
local _dummy_func = function()
end
function _M.runCMD(ipv4, port, cmd_tbl, ret_func)
    if type(cmd_tbl) ~= "table" then
        return false
    end
    -- prepare input
    ipv4 = type(ipv4) == "string" and ipv4 or "127.0.0.1"
    port = port and port or 6379
    ret_func = type(ret_func) == "function" and ret_func or _dummy_func
    -- open chann
    _M._data = ""
    _M._chann = NetCore.openChann("tcp")
    local msg = ""
    if #cmd_tbl > 0 then
        msg = Resp.encode(unpack(cmd_tbl))
    else
        msg = Resp.encode(nil)
    end
    local callback = function(chann, event_name, accept_chann, c_msg)
        if event_name == "event_connected" then
            if type(msg) == "string" then
                chann:send(msg)
            else
                ret_func(nil)
            end
        elseif event_name == "event_recv" then
            _M._data = _M._data .. chann:recv()
            local consumed, output, typ = Resp.decode(_M._data)
            if consumed == _M._data:len() then
                _M._data = ""
                ret_func(output)
            elseif consumed == Resp.EILSEQ then
                -- Found illegal byte sequence
                _M._data = ""
                chann:close()
                ret_func(nil)
            end
        elseif event_name == "event_disconnect" then
            _M._data = ""
            chann:close()
            ret_func(nil)
        end
    end
    _M._chann:setCallback(callback)
    _M._chann:connect(ipv4, port)
    return true
end

return _M
