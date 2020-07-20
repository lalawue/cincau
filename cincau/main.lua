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
    local mnet_config = [===[
--
-- cincau web framework mnet config

return {
    ipport = "127.0.0.1:8080",
    logger = require("base.logger"),
    render = require("template.etlua")
}
]===]
    local path = proj_dir .. "/config/proj_config.lua"
    print("mnet config: ", path)
    writeToFile(path, mnet_config)
end

-- nginx config
local function _createEngineNginx(core_dir, proj_dir)
    local nginx_config = ""
end

-- create project skeleton
local function _createProjectSkeleton(core_dir, proj_dir, engine_type)
    if not _check_params(core_dir, proj_dir, engine_type) then
        return false
    end
    -- create dirs
    mkDir(proj_dir)
    local dir_tbl = {"config", "controllers", "models", "views", "logs", "static", "tmp"}
    for _, v in ipairs(dir_tbl) do
        local dir_path = proj_dir .. "/" .. v
        mkDir(dir_path)
    end
    print("---")
    -- copy engine config
    local engine_path = ""
    if engine_type == "mnet" then
        engine_path = core_dir .. "/engine/server_mnet.lua"
        _createEngineMnet(core_dir, proj_dir)
    else -- nginx
        engine_path = core_dir .. "/engine/server_nginx.lua"
        _createEngineNginx(core_dir, proj_dir)
    end
    copyFile(engine_path, proj_dir .. "/server.lua")    
    -- copy demo base
    local demo_dir = core_dir .. "/demo"
    local demo_tbl = {"/main.lua", "/run_app.sh"}
    for _, v in ipairs(demo_tbl) do
        copyFile(demo_dir .. v, proj_dir .. v)
    end
    return true
end

-- start creation
_createProjectSkeleton(...)