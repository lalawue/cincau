--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

-- this module only for mnet
--
local _valid = require("config").engine_type == "mnet"
local ThreaBroker = require("bridge.thread_broker")
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

return _M
