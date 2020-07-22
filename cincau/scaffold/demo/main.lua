--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

require("base.scratch")
local config = require("config") -- app/config
local server = require("server")
local router = require("router")

local logger = config.logger

-- server:run(...) in protected mode
xpcall(
    server.run,
    function(msg)
        print("\nPANIC : " .. tostring(msg) .. "\n")
        print(debug.traceback())
    end,
    --- args with self, ...
    server,
    config,
    function(config, req, response)
        local func, params = router:resolve(req.method, req.path)
        if func then
            func(config, req, response, params)
        else
            logger.err("router failed to resolve method:%s path:%s", req.method, req.path)
        end
    end
)
