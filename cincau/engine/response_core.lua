--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local _M = {}
_M.__index = _M

local _status_code_msg = {
    ["100"] = "Continue",
    ["200"] = "OK",
    ["301"] = "Moved Permanently",
    ["302"] = "Found",
    ["401"] = "Unauthorized",
    ["403"] = "Forbidden",
    ["404"] = "Not Found",
    ["500"] = "Internal Server Error"
}

-- only support chunked output
local function _validateOption(opt)
    if type(opt.en_chunked_length) == "boolean" and type(opt.fn_chunked_callback) == "function" then
        return opt
    else
        return nil
    end
end

--[[
option as
{
    en_chunked_length,
    fn_chunked_callback,
    fn_set_header, -- overide default
    fn_set_status,
}
--]]
function _M.new(option)
    option = _validateOption(option)
    if option == nil then
        return nil
    end
    local response = setmetatable({}, _M)
    response.opt = option
    response.http = {} -- { header, status_code }
    if not option.fn_set_header then
        response.http.header = {} -- optional
        response:setHeader("Server", "mnet/v20200717")
    end
    response:setStatus(200)
    response:setHeader("X-Powered-By", "cincau framework")
    response:setHeader("Transfer-Encoding", "chunked")
    return response
end

function _M:setStatus(status_code)
    self.http.status_code = status_code
    if self.opt.fn_set_status then
        self.opt.fn_set_status(status_code)
    end
end

function _M:setHeader(key, value)
    if not self.opt.fn_set_header then
        self.http.header[key] = value
    end
end

-- makeup header before appendBody
local function _makeHeader(self)
    if self.opt.fn_set_header or self._has_make_header then
        return
    end
    self._has_make_header = true -- mark make
    local content = ""
    local http = self.http
    local status_msg = _status_code_msg[tostring(http.status_code)]
    if status_msg then
        content = "HTTP/1.1 " .. tostring(http.status_code) .. " " .. status_msg .. "\r\n"
    else
        content = "HTTP/1.1 500 " .. _status_code_msg["500"] .. "\r\n"
    end
    for k, v in pairs(http.header) do
        content = content .. string.format("%s: %s\r\n", k, v)
    end
    content = content .. "\r\n"
    self.opt.fn_chunked_callback(content)
end

local function _hexlen(str)
    return string.format("%X", str:len())
end

-- appendBody after makeHeader
function _M:appendBody(data)
    if type(data) ~= "string" then
        return
    end
    _makeHeader(self)
    local opt = self.opt
    local http = self.http
    if http.status_code == 500 then
        local msg = "<html><h1>500 Internal Server Error</h1></html>"
        if opt.en_chunked_length then
            msg = _hexlen(msg) .. "\r\n" .. msg .. "\r\n"
        end
        opt.fn_chunked_callback(msg)
    elseif data:len() > 0 then
        if opt.en_chunked_length then
            data = _hexlen(data) .. "\r\n" .. data .. "\r\n"
        end
        opt.fn_chunked_callback(data)
    end
end

function _M:finishResponse()
    _makeHeader(self)
    if self.opt.en_chunked_length then
        self.opt.fn_chunked_callback("0\r\n\r\n")
    end
end

return _M
