--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

package.path = package.path .. ";cincau/?.lua;"

require("base.scratch")
local Request = require("engine.request_core")

local arg_filename = ...
if arg_filename == nil then
    print("Usage: lua run_test.lua TEST_TABLE_LUA")
    os.exit(0)
end

-- extra io function
--

function io.readFile(file_path)
    local f = io.open(file_path, "rb")
    if f then
        local data = f:read("*a")
        f:close()
        return data
    end
    return nil
end

function io.appendFile(file_path, data)
    local f = io.open(file_path, "a+")
    if f then
        f:write(data)
        f:close()
        return true
    end
    return false
end

-- run test interface
--

local _M = {}
_M.__index = {}

function _M:readHeader(content)
    local s, e = content:find("\r\n\r\n")
    local substr = content:sub(1, s + 2)
    local tbl = {}
    for i, line in ipairs(substr:split("\r\n")) do
        if i > 1 and line:len() > 0 then
            local kv = line:split(": ")
            tbl[kv[1]] = kv[2]
        end
    end
    return tbl, content:sub(e + 1)
end

function _M:runMultiPartTestCase(filepath, callback)
    local content = io.readFile(filepath)
    local header_tbl, body = self:readHeader(content)
    local fd_tbl = {} -- context
    local buf_size = 8192
    if Request.isMultiPartFormData(fd_tbl, "POST", header_tbl) then
        repeat
            local len = math.min(buf_size, body:len())
            local data = body:sub(1, len)
            body = (body:len() > len) and body:sub(len + 1) or ""
            Request.multiPartReadBody(fd_tbl, data, callback)
        until body:len() <= 0
    end
end
--

--[[
    test_case_tbl would be
    {
        [1] = {
            case_name = "",
            result = {
                [1] = {
                        name = "",
                        content_type = ""
                },
                [2] = ...
            },
        },
        [2] = ...
    }
]]
function _M:runMultiPartTestCaseFile(filename)
    local tbl = dofile(filename)
    for _, test_case in ipairs(tbl) do
        local path = "test/cases/" .. test_case.case_name
        local result_tbl = test_case.result
        local idx = 1
        local success_count = 0
        local failed_count = 0
        self:runMultiPartTestCase(
            path,
            function(name, content_type, data)
                if data ~= nil then
                    return
                end
                local rtbl = result_tbl[idx]
                if name == rtbl.name and content_type == rtbl.content_type then
                    success_count = success_count + 1
                else
                    failed_count = failed_count + 1
                end
                idx = idx + 1
            end
        )
        io.write(string.format("(s:%d f:%d)  ", success_count, failed_count))
        if success_count + failed_count == #result_tbl then
            if failed_count > 0 then
                print(test_case.case_name .. "\t FAILED !!!")
            else
                print(test_case.case_name .. "\t PASSED")
            end
        else
            print(test_case.case_name .. "\t PASSED")
        end
    end
end

_M:runMultiPartTestCaseFile(arg_filename)
