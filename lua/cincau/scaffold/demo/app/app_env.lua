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
        local config = CincauConfig
        os.execute("mkdir -p " .. config.log_dir)
        local logger = config.logger
        -- open comment if you need logger to file
        --logger.setDir(config.log_dir)
        logger.setLevel(config.debug_on and logger.DEBUG or logger.INFO)
    end
    CincauRouter = require("app.app_router")
    CincauTracebackHandler = require("cincau.base.scratch").tracebackHandler
    print("version: " .. ver.version)
    if pcall(require, 'app.app_binary') then
        print("  build: " .. require('app.app_version'))
    end
    require("cincau.base.template").caching(not CincauConfig.debug_on)
elseif ngx and ngx.log then
    ngx.log(ngx.ERR, "can not find cincau")
else
    print("Can not found cincau core dir: ", ver)
    assert(nil)
    os.exit(0)
end