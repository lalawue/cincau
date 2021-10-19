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
        local path_tbl = {
            core_dir .. '?.lua',
            core_dir .. '?/init.lua',
            'app/?.lua',
            'app/?/init.lua',
            'lib/share/lua/5.1/?.lua',
            'lib/share/lua/5.1/?/init.lua',
            '',
        }
        package.path = table.concat(path_tbl, ';') .. package.path
	    package.cpath = "lib/lib/lua/5.1/?.so;" .. package.cpath
        load_lib = true
        break
    end
end

if load_lib then
    require("moocscript.core")
    require("base.scratch")
    CincauEnginType = ngx and "nginx" or "mnet"
    CincauConfig = require("config")
    if CincauEnginType == "nginx" then
        CincauServer = require("engine.nginx.server")
    else
        CincauServer = require("engine.mnet.server")
    end
    CincauRouter = require("router")
    CincauTracebackHandler = require("base.scratch").tracebackHandler
    io.printf("version: %s", require("base.version").version)
    require("base.template").caching(not CincauConfig.debug_on)
else
    print("Can not found cincau core dir, exit !")
    assert(nil)
    os.exit(0)
end