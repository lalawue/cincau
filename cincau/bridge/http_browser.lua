--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local TcpRaw = require("bridge.tcp_stream.tcp_raw")
local TcpSSL = require("bridge.tcp_stream.tcp_ssl")
local FileManager = require("base.file_manager")
local UrlCore = require("base.url_core")
local HttpParser = require("ffi_hyperparser")

local Browser = {}
Browser.__index = Browser

-- create browser in coroutine
function Browser.newBrowser()
    if coroutine.running() == nil then
        return nil
    end
    local brw = {
        _chann = nil, -- one tcp chann
        _hp = nil, -- hyperparser
        _url_info = nil -- path, host, port
    }
    return setmetatable(brw, Browser)
end

-- act like curl, accept encoding gzip
local function _buildHttpRequest(method, url_info, option, data)
    if type(method) ~= "string" then
        return nil
    end
    local sub_path = "/"
    if url_info.path and url_info.path:len() > 0 then
        sub_path = url_info.path
    end
    if type(url_info.query) == "table" then
        local query = UrlCore.buildQuery(url_info.query)
        if query and query:len() > 0 then
            sub_path = sub_path .. "?" .. query
        end
    end
    local tbl = {}
    tbl[#tbl + 1] = string.format("%s %s HTTP/1.1", method, sub_path)
    if url_info.host then
        tbl[#tbl + 1] = "Host: " .. url_info.host
    end
    tbl[#tbl + 1] = "User-Agent: cincau/v20200803"
    if option and option.inflate then
        tbl[#tbl + 1] = "Accept-Encoding: gzip"
    end
    if option and type(option.header) == "table" then
        for k, v in pairs(option.header) do
            tbl[#tbl + 1] = k .. ": " .. v
        end
    end
    if data then
        tbl[#tbl + 1] = "Content-Length: " .. data:len()
    end
    tbl[#tbl + 1] = "\r\n"
    if data then
        tbl[#tbl + 1] = data
    end
    return table.concat(tbl, "\r\n")
end

local function _processRecvData(brw, data)
    local ret, state, http_tbl = brw._hp:process(data)
    if ret < 0 then
        return ret
    end
    return ret, state, http_tbl
end

-- return empty when gzip and not finish
local function _constructContent(http_tbl, option, is_finish)
    if http_tbl.contents == nil then
        return ""
    end
    local output_content = ""
    local input_content = table.concat(http_tbl.contents)
    local encoding_desc = http_tbl.header["Content-Encoding"]
    local is_gzip = encoding_desc == "gzip"
    if is_gzip and is_finish then
        output_content = FileManager.inflate(input_content)
    elseif not is_gzip then
        output_content = input_content
    end
    if output_content:len() > 0 then
        http_tbl.contents = nil
    end
    return output_content
end

--[[
    request HTTP/HTTPS URL
    option = {
        inflate = false, -- default
        header = header, -- table
        recv_cb = function(header_tbl, data_string) end, -- for receiving data
    }
    return header_tbl, data_string (if no recv_cb function set)
]]
local _dummy_cb = function()
end
function Browser:requestURL(site_url, option)
    if type(site_url) ~= "string" then
        return false
    end

    if self._chann then
        return false
    end

    local url_info = UrlCore.parse(site_url)
    if not url_info then
        return false
    end

    if type(url_info.scheme) ~= "string" then
        return false
    end

    if url_info.scheme ~= "http" and url_info.scheme ~= "https" then
        return false
    elseif url_info.scheme == "https" and not TcpSSL then
        return false
    end

    if type(url_info.host) ~= "string" then
        return false
    end

    self._url_info = url_info

    local ipv4 = nil
    local port = nil
    local ipv4_pattern = "%d-%.%d-%.%d-%.%d+"
    if url_info.host:find(ipv4_pattern) then
        ipv4 = url_info.host:match("(" .. ipv4_pattern .. ")")
        port = url_info.port
    else
        local ret = require("bridge.mediator").queryDomain(url_info.host)
        if not ret then
            return false
        end
        ipv4 = ret
        port = url_info.port
    end

    if url_info.scheme == "http" then
        self._chann = TcpRaw.openChann()
        port = port and tonumber(port) or 80
    else
        self._chann = TcpSSL.openChann()
        port = port and tonumber(port) or 443
    end
    url_info = nil -- reset nil

    local brw = self
    local recv_cb = option and option.recv_cb or _dummy_cb
    local callback = function(chann, event_name, _, _)
        if event_name == "event_connected" then
            brw._hp = HttpParser.createParser("RESPONSE")
            local data = _buildHttpRequest("GET", brw._url_info, option)
            chann:send(data)
        elseif event_name == "event_recv" then
            local ret, state, http_tbl = _processRecvData(brw, chann:recv())
            if ret < 0 then
                brw:closeURL()
                brw = nil
                recv_cb(nil, nil)
            elseif state == HttpParser.STATE_BODY_CONTINUE and http_tbl then
                local content = _constructContent(http_tbl, option, false)
                if content:len() > 0 then
                    recv_cb(http_tbl, content)
                end
            elseif state == HttpParser.STATE_BODY_FINISH and http_tbl then
                -- FIXME: consider status code 3XX
                -- FIXME: support cookies
                -- FIXME: support keep-alive
                local content = _constructContent(http_tbl, option, true)
                brw:closeURL()
                brw = nil
                recv_cb(http_tbl, content)
                recv_cb(http_tbl, nil)
            end
        elseif event_name == "event_disconnect" then
            brw:closeURL()
            brw = nil
            recv_cb(nil, nil)
        end
    end
    self._chann:setCallback(callback)
    self._chann:connectAddr(ipv4, port)
end

-- return true/false, http header, data, one at a time
function Browser:postURL(site_url, data)
    if type(site_url) ~= "string" or not coroutine.running() then
        return false
    end
    return false
end

function Browser:closeURL()
    if self._chann then
        self._chann:closeChann()
        self._chann = nil
    end
    if self._hp then
        self._hp:destroy()
        self._hp = nil
    end
    self._url_info = nil
end

function Browser:onLoopEvent()
    if self._chann.onLoopEvent then
        return self._chann:onLoopEvent()
    end
    return true
end

return Browser
