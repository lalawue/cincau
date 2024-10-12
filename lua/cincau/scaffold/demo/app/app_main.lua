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

-- resolve http://, func(config, req, response)
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

-- resolve ws://, func(config, req, response, params)
local function ws_resolve(ws_path)
    local func, params = Router:resolve("WS", ws_path)
    if func then
        return func, params
    end
end

local function runApp()
    Router:loadModel(Config)
    Server.run(Config, http_callback, ws_resolve)
end

cincau_xpcall(runApp)
