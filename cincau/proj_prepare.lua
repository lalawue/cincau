--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

--
-- generate demo project
--

local core_dir, proj_dir, engine_type = ...

package.path = package.path .. string.format(";%s/?.lua", core_dir)
local Logger = require("base.logger")
local FileManager = require("base.file_manager")

-- check input params
local function _check_params(core_dir, proj_dir, engine_type)
    if core_dir == nil or proj_dir == nil or engine_type == nil then
        print("please provide core_dir proj_dir engine_type !")
        return false
    end
    engine_type = string.lower(engine_type)
    if engine_type == "mnet" or engine_type == "nginx" then
        print("create cincau demo project with:")
        print("core_dir:", core_dir)
        print("proj_dir:", proj_dir)
        print("engine_type:", engine_type)
        return true
    end
end

-- operation function
local _runCmd = os.execute

local function _mkDir(dir)
    local cmd = "mkdir -p " .. dir
    print(cmd)
    _runCmd(cmd)
end

local function _copyFile(src, dest)
    local cmd = "cp -af " .. src .. " " .. dest
    print(cmd)
    _runCmd(cmd)
end

-- create demo app
local function _createAppSkeleton(core_dir, proj_dir, engine_type)
    print("---")
    local app_dir = proj_dir .. "/app/"
    _mkDir(app_dir)
    -- copy engine
    local engine_dir = core_dir .. "/engine/" .. engine_type
    _copyFile(engine_dir .. "/server.lua", app_dir .. "/server.lua")
    -- copy others
    _copyFile(core_dir .. "/scaffold/demo/*", app_dir)
    local scaffold_dir = core_dir .. "/scaffold/" .. engine_type
    -- replace config proj_dir
    local content = FileManager.readFile(scaffold_dir .. "/config.lua")
    content = content:gsub("__PROJ_DIR__", "\"" .. proj_dir .. "\"")
    FileManager.saveFile(app_dir .. "/config.lua", content)
    print("write to " .. app_dir .. "/config.lua")
end

-- create project skeleton
local function _createProjectSkeleton(core_dir, proj_dir, engine_type)
    if not _check_params(core_dir, proj_dir, engine_type) then
        return false
    end
    -- create proj dirs
    print("--")
    local proj_tbl = {"/tmp", "/" .. Logger.getOutputDir()}
    for _, v in ipairs(proj_tbl) do
        _mkDir(proj_dir .. v)
    end
    -- copy scaffold
    local scaffold_dir = core_dir .. "/scaffold/" .. engine_type
    _copyFile(scaffold_dir .. "/run_app.sh", proj_dir .. "/run_app.sh")
    if engine_type == "nginx" then
        local conf_dir = proj_dir .. "/config"
        _mkDir(conf_dir)
        _copyFile(scaffold_dir .. "/mime.types", conf_dir .. "/mime.types")
        _copyFile(scaffold_dir .. "/nginx.conf", conf_dir .. "/nginx.conf")
    end
    -- create app dir
    _createAppSkeleton(core_dir, proj_dir, engine_type)
end

-- start creation
_createProjectSkeleton(core_dir, proj_dir, engine_type)
