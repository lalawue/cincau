--
-- Copyright (c) 2021 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local load_lib = false

for path in package.path:gmatch("[^;]+") do
    local len = path:len()
    path = path:sub(1, len - 5)
    local f = io.open(path .. "cincau/page_core.mooc", "r")
    if f then
        f:close()
        local core_dir = path .. "cincau/"
        package.path = package.path .. ";" .. core_dir .. "?.lua;app/?.lua"
        load_lib = true
        break
    end
end

if load_lib then
    require("moocscript.core")
    require("base.scratch")
    CincauConfig = require("config")
    CincauServer = require("server")
    CincauRouter = require("router")
    CincauTracebackHandler = require("base.scratch").tracebackHandler
    CincauConfig.logger.info("version: %s", require("base.version").version)
    CincauEnginType = ngx and "nginx" or "mnet"
else
    print("Can not found cincau core dir, exit !")
    assert(nil)
    os.exit(0)
end