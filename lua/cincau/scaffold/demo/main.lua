--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

require("app.env")
require("base.scratch")
local Config = require("config")
local Server = require("server")
local Router = require("router")

local Logger = Config.logger

-- server:run(...) in protected mode
xpcall(
    Server.run,
    function(msg)
        print("\nPANIC : " .. tostring(msg) .. "\n")
        print(debug.traceback())
    end,
    Server,
    Config,
    function(config, req, response)
        local func, params = Router:resolve(req.method, req.path)
        if func then
            func(config, req, response, params)
        elseif Router.pageNotFound then
            Router:pageNotFound(config, req, response, params)
        else
            Logger.err("router failed to resolve method:%s path:%s", req.method, req.path)
        end
    end
)
