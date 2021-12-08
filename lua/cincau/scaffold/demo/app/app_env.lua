--
-- Copyright (c) 2021 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local ver = pcall(reqiure, "cincau.base.version")

if ver then
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
    require("cincau.base.template").caching(not CincauConfig.debug_on)
else
    print("Can not found cincau core dir, exit !")
    assert(nil)
    os.exit(0)
end