--
-- Copyright (c) 2021 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local status, ver = pcall(require, "cincau.base.version")

if status then
    require("moocscript.core")
    require("cincau.base.scratch")
    CincauEnginType = ngx and "nginx" or "mnet"
    CincauConfig = require("app.app_config")
    if CincauEnginType == "nginx" then
        CincauServer = require("cincau.engine.nginx.server")
    else
        CincauServer = require("cincau.engine.mnet.server")
    end
    CincauRouter = require("app.app_router")
    CincauTracebackHandler = require("cincau.base.scratch").tracebackHandler
    print("version: " .. ver.version)
    if pcall(require, 'app.app_binary') then
        print("  build: " .. require('app.app_version'))
    end
    require("cincau.base.template").caching(not CincauConfig.debug_on)
else
    print("Can not found cincau core dir: ", ver)
    assert(nil)
    os.exit(0)
end