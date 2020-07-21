--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

--
-- generate demo project
--

-- check input params
local function _check_params(core_dir, proj_dir, engine_type)
    if core_dir == nil or proj_dir == nil or engine_type == nil then
        print("please provide core_dir, proj_dir, engine_type !")
        return false
    end
    engine_type = string.lower(engine_type)
    if engine_type == "mnet" or engine_type == "nginx" then
        print("create cincau demo project with:")
        print("core_dir:", core_dir)
        print("proj_dir:", proj_dir)
        print("engine_type:", engine_type)
        print("---")
        return true
    end
end

-- operation function
local runCmd = os.execute
local function mkDir(dir)
    local cmd = "mkdir -p " .. dir
    print(cmd)
    runCmd(cmd)
end

local function copyFile(src, dest)
    local cmd = "cp -f " .. src .. " " .. dest
    print(cmd)
    runCmd(cmd)
end

local function writeToFile(path, data)
    local fp = io.open(path, "wb")
    if fp == nil then
        print("failed to create file: ", path)
        os.exit()
    end
    if type(data) == "string" then
        fp:write(data)
    end
    fp:close()
end

local function readAndReplace(path, replace_tbl)
    local fp = io.open(path, "rb")
    if fp == nil then
        print("failed to read file: ", path)
        os.exit()
    end
    local content = fp:read("*a")
    fp:close()
    if content and replace_tbl then
        for i = 1, #replace_tbl, 2 do
            local pattern = replace_tbl[i]
            local text = replace_tbl[i + 1]
            content = content:gsub(pattern, text)
        end
    end
    return content
end

-- mnet config
local function _createEngineMnet(core_dir, proj_dir)
    local proj_config = readAndReplace(core_dir .. "/scaffold/config_mnet.lua")
    local to_path = proj_dir .. "/app/config.lua"
    print("engine config -> " .. to_path)
    writeToFile(to_path, proj_config)
end

-- nginx config
local function _createEngineNginx(core_dir, proj_dir)
    -- generate nginx config for openresty
    local nginx_config = readAndReplace(core_dir .. "/scaffold/nginx.conf")
    local path = proj_dir .. "/config/nginx.conf"
    print("nginx config -> " .. path)
    writeToFile(path, nginx_config)
    -- nginx proj config
    local proj_config = readAndReplace(core_dir .. "/scaffold/config_nginx.lua")
    path = proj_dir .. "/app/config.lua"
    print("engine config -> " .. path)
    writeToFile(path, proj_config)
end

-- create project skeleton
local function _createProjectSkeleton(core_dir, proj_dir, engine_type)
    if not _check_params(core_dir, proj_dir, engine_type) then
        return false
    end
    package.path = package.path .. string.format(";%s/?.lua;", core_dir)
    print(package.path)
    local logger = require("base.logger")
    -- create dirs
    mkDir(proj_dir)
    local app_tbl = {"controllers", "models", "views", "static"}
    for _, v in ipairs(app_tbl) do
        local dir_path = proj_dir .. "/app/" .. v
        mkDir(dir_path)
    end
    local proj_tbl = {"config", "tmp", logger.getOutputDir()}
    for _, v in ipairs(proj_tbl) do
        local dir_path = proj_dir .. "/" .. v
        mkDir(dir_path)
    end
    print("---")
    -- copy files
    local scaffold_dir = core_dir .. "/scaffold"
    local engine_path = ""
    local runapp_path = ""
    if engine_type == "mnet" then
        engine_path = core_dir .. "/engine/server_mnet.lua"
        runapp_path = scaffold_dir .. "/runapp_mnet.sh"
        _createEngineMnet(core_dir, proj_dir)
    else -- nginx
        engine_path = core_dir .. "/engine/server_nginx.lua"
        runapp_path = scaffold_dir .. "/runapp_nginx.sh"
        _createEngineNginx(core_dir, proj_dir)
        copyFile(scaffold_dir .. "/mime.types", proj_dir .. "/config/mime.types")
    end
    copyFile(engine_path, proj_dir .. "/app/server.lua")
    copyFile(runapp_path, proj_dir .. "/run_app.sh")
    copyFile(scaffold_dir .. "/proj_main.lua", proj_dir .. "/app/main.lua")
    copyFile(scaffold_dir .. "/proj_router.lua", proj_dir .. "/app/router.lua")
    copyFile(scaffold_dir .. "/ctrl_index.lua", proj_dir .. "/app/controllers/ctrl_index.lua")
    copyFile(scaffold_dir .. "/ctrl_hello.lua", proj_dir .. "/app/controllers/ctrl_hello.lua")
    return true
end

-- start creation
_createProjectSkeleton(...)
