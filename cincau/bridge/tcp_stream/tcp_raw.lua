--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

--
-- raw tcp stated stream, interface should be same as tcp_ssl
--

local NetCore = require("ffi_mnet")

local ChannRaw = {
    _options = nil,
    _chann = nil,
    _callback = nil
}
ChannRaw.__index = ChannRaw

local _has_init = false
function ChannRaw.openChann(options)
    local chann = setmetatable({}, ChannRaw)
    chann._options = options
    chann._chann = NetCore.openChann("tcp")
    return chann
end

function ChannRaw:closeChann()
    if self._chann then
        self._chann:close()
        self._chann = nil
    end
end

function ChannRaw:connectAddr(ipv4, port)
    if self._chann and self._chann:state() ~= "state_connected" then
        self._chann:connect(ipv4, port)
        return true
    else
        return false
    end
end

-- callback params should be (self, event_name, accept_chann, c_msg)
function ChannRaw:setCallback(callback)
    if not callback then
        return
    end
    self._callback = callback
    self._chann:setCallback(
        function(chann, event_name, accept_chann, c_msg)
            if event_name == "event_connected" then
                self._callback(self, event_name, accept_chann, c_msg)
            elseif event_name == "event_recv" then
                self._callback(self, event_name, nil, c_msg)
            elseif event_name == "event_send" then
                self._callback(self, event_name, nil, c_msg)
            elseif event_name == "event_disconnect" then
                self._callback(self, event_name, nil, c_msg)
            elseif event_name == "event_accept" then
                local chann_raw = setmetatable({}, ChannRaw)
                chann_raw.m_chann = accept_chann
                self._callback(self, event_name, chann_raw, c_msg)
            end
        end
    )
end

function ChannRaw:send(data)
    if self._chann and self._chann:state() == "state_connected" then
        return self._chann:send(data)
    end
end

function ChannRaw:recv()
    if self._chann and self._chann:state() == "state_connected" then
        return self._chann:recv()
    end
end

-- event_name always "event_loop", return true to keep event
function ChannRaw:onLoopEvent()
    return true
end

return ChannRaw
