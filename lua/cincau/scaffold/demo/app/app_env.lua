--
-- Copyright (c) 2021 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

for path in package.path:gmatch("[^;]+") do
    local len = path:len()
    local path = path:sub(1, len - 5)
    local f = io.open(path .. "cincau/page_core.mooc", "r")
    if f then
        f:close()
        package.path = path .. "cincau/?.lua;" .. package.path
        package.path = 'app/?.lua;' .. package.path
        break
    end
end

if package.path:find('cincau') then
    require("moocscript.core")
    require("base.scratch")
    CincauEnginType = ngx and "nginx" or "mnet"
    CincauConfig = require("app_config")
    if CincauEnginType == "nginx" then
        CincauServer = require("engine.nginx.server")
    else
        CincauServer = require("engine.mnet.server")
    end
    CincauRouter = require("app_router")
    CincauTracebackHandler = require("base.scratch").tracebackHandler
    io.printf("version: %s", require("base.version").version)
    require("base.template").caching(not CincauConfig.debug_on)
else
    print("Can not found cincau core dir, exit !")
    assert(nil)
    os.exit(0)
end