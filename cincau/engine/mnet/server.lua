--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local NetCore = require("ffi_mnet")
local HttpParser = require("ffi_hyperparser")
local Request = require("engine.request_core")
local Response = require("engine.response_core")
local UrlCore = require("base.neturl")
local FileManager = require("base.file_manager")

local Serv = {}

-- close chann and destroy http parser
local function _clientDestroy(chann)
    chann:close()
    chann._http_parser:destroy()
end

-- response option
local _response_option = {
    en_chunked_length = true, -- append chunked body length
    fn_chunked_callback = nil,
    fn_set_header = nil, -- construct header
    fn_set_status = nil
}
_response_option.__index = _response_option

local function _updateRequest(req)
    if req.method ~= "POST" then
        return
    end
    local content_type = req.header["Content-Type"]
    local is_url_encoded = content_type and content_type:find("application/x-www-form-urlencoded")
    if is_url_encoded then
    elseif req.body:len() > 0 then
        req.post_args = UrlCore.parseQuery(req.body)
    else
        req.post_args = {}
    end
end

-- return filename
local function _readMultiPartData(fd_tbl, header, contents)
    if not Request.isMultiPartFormData(fd_tbl, header) then
        return false, nil
    end
    local fname = nil
    local raw_data = contents and table.concat(contents) or ""
    Request.multiPartReadBody(
        fd_tbl,
        raw_data,
        function(filename, content_type, data, end_mak)
            fname = filename
            FileManager.appendFile("tmp/" .. filename, data)
        end
    )
    return true, fname
end

-- receive client data then parse to http method, path, header, content
local function _onClientEventCallback(chann, event_name, _)
    if event_name == "event_recv" then
        local data = chann:recv()
        if data == nil then
            _clientDestroy(chann)
            return
        end
        -- parse raw data to http protoco info
        local ret_value, state, http_tbl = chann._http_parser:process(data)
        if ret_value < 0 then
            return
        end
        local content = nil
        if state == HttpParser.STATE_BODY_CONTINUE and http_tbl then
            if _readMultiPartData(chann._fd_tbl, http_tbl.header, http_tbl.contents) then
                http_tbl.contents = nil
            end
        end
        if state == HttpParser.STATE_BODY_FINISH and http_tbl then
            -- multipart/form-data
            local ret, fname = _readMultiPartData(chann._fd_tbl, http_tbl.header, http_tbl.contents)
            if ret then
                content = fname
                http_tbl.contents = nil
            end
            -- not multipart
            if not content and http_tbl.contents then
                content = table.concat(http_tbl.contents)
                http_tbl.contents = nil
            end
            if chann._http_callback then
                -- create req
                local req = Request.new(http_tbl.method, http_tbl.url, http_tbl.header, content or "")
                _updateRequest(req)
                -- create response
                local option = setmetatable({}, _response_option)
                option.fn_chunked_callback = function(data)
                    chann:send(data)
                end
                local response = Response.new(option)
                -- callback
                chann._http_callback(chann._config, req, response)
                -- finish response
                response:finishResponse()
            end
        end
    elseif event_name == "event_disconnect" then
        _clientDestroy(chann)
    end
end

-- run server, http_callback(config, req, response)
function Serv:run(config, http_callback)
    local logger = config.logger
    local addr = NetCore.parseIpPort(config.ipport)
    if type(addr.ip) ~= "string" or type(addr.port) ~= "number" then
        logger.err("invalid ipport")
        return
    else
        logger.info("listen on %s:%d", addr.ip, addr.port)
    end
    NetCore.init()
    self.svr_tcp = NetCore.openChann("tcp")
    self.svr_tcp:listen(addr.ip, addr.port, 1024)
    self.svr_tcp:setCallback(
        function(_, event_name, accept)
            if event_name == "event_accept" and accept ~= nil then
                accept._config = config
                accept._http_callback = http_callback
                accept._http_parser = HttpParser.createParser("REQUEST")
                accept._fd_tbl = {}
                accept:setCallback(_onClientEventCallback)
            end
        end
    )
    -- mnet event loop
    while true do
        NetCore.poll(1000)
    end
end

return Serv
