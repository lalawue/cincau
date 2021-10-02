--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

require("app.env")
local Base = require("base.scratch")

local function runApp()
    print("version: ", require("base.version").version)
    local Config = require("config")
    local Server = require("server")
    local Router = require("router")

    local Logger = Config.logger

    Server.run(
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
end

xpcall(runApp, Base.tracebackHandler)
