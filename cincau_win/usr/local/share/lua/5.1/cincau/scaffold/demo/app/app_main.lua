--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

if not CincauEnginType then
    require("app.app_env")
end

local Server = CincauServer
local Config = CincauConfig
local Router = CincauRouter

local function http_callback(config, req, response)
    local func, params = Router:resolve(req.method, req.path)
    if func then
        func(config, req, response, params)
    elseif Router.pageNotFound then
        Router:pageNotFound(config, req, response, params)
    else
        Config.logger.err("router failed to resolve method:%s path:%s", req.method, req.path)
    end
end

local function runApp()
    Router:loadModel(Config)
    Server.run(Config, http_callback)
end

xpcall(runApp, CincauTracebackHandler)
