--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local FileSystem = require("base.ffi_lfs")
local Zlib = require("base.ffi_zlib")

local FileManager = {
    _sandbox_dir = nil,
    _logger = nil
}

-- restrict to proj dir
function FileManager.setupSandboxEnv(config)
    FileManager._sandbox_dir = config.proj_dir
    FileManager._logger = config.logger
end

function FileManager.validatePath(path)
    if FileManager._sandbox_dir and path then
        local ret = false
        ret = (path:find("/", 1, true) == 1) and (path:find(FileManager._sandbox_dir, 1, true) ~= 1)
        ret = ret or (path:find("..", 1, true) == 1)
        if ret and FileManager._logger then
            FileManager._logger.err("invalid path: '%s', out of sandbox", path)
            print(debug.traceback())
            os.exit(1)
        end
    end
end

function FileManager.mkdir(dir_path)
    FileManager.validatePath(dir_path)
    FileSystem.mkdir(dir_path)
end

function FileManager.stat(path)
    FileManager.validatePath(path)
    return FileSystem.attributes(path)
end

-- save data to path
function FileManager.saveFile(file_path, data)
    FileManager.validatePath(file_path)
    local f = io.open(file_path, "wb")
    if f then
        f:write(data)
        f:close()
        return true
    end
    return false
end

function FileManager.readFile(file_path)
    FileManager.validatePath(file_path)
    local f = io.open(file_path, "rb")
    if f then
        local data = f:read("*a")
        f:close()
        return data
    end
    return nil
end

function FileManager.appendFile(file_path, data)
    FileManager.validatePath(file_path)
    local f = io.open(file_path, "a+")
    if f then
        f:write(data)
        f:close()
        return true
    end
    return false
end

function FileManager.removeFile(file_path)
    FileManager.validatePath(file_path)
    os.remove(file_path)
end

function FileManager.renameFile(oldname, newname)
    FileManager.validatePath(oldname)
    FileManager.validatePath(newname)
    os.rename(oldname, newname)
end

function FileManager.inflate(input_content)
    if type(input_content) ~= "string" then
        return nil
    end
    local function _input(buf_size)
        local min_len = math.min(buf_size, input_content:len())
        if min_len > 0 then
            local data = input_content:sub(1, min_len)
            input_content = input_content:sub(1 + min_len)
            return data
        end
    end
    local tbl = {}
    local function _ouput(data)
        tbl[#tbl + 1] = data
    end
    local success, err_msg = Zlib.inflateGzip(_input, _ouput)
    if not success then
        return table.concat(tbl), err_msg
    end
    return table.concat(tbl)
end

function FileManager.deflate(input_content)
    if type(input_content) ~= "string" then
        return nil
    end
    local function _input(buf_size)
        local min_len = math.min(buf_size, input_content:len())
        if min_len > 0 then
            local data = input_content:sub(1, min_len)
            input_content = input_content:sub(1 + min_len)
            return data
        end
    end
    local tbl = {}
    local function _ouput(data)
        tbl[#tbl + 1] = data
    end
    local success, err_msg = Zlib.deflateGzip(_input, _ouput)
    if not success then
        return table.concat(tbl), err_msg
    end
    return table.concat(tbl)
end

return FileManager
