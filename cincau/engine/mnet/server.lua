--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local NetCore = require("ffi_mnet")
local DnsCore = require("bridge.ffi_mdns")
local HttpParser = require("ffi_hyperparser")
local Request = require("engine.request_core")
local Response = require("engine.response_core")
local UrlCore = require("base.url_core")
local FileManager = require("base.file_manager")
local ThreadBroker = require("bridge.thread_broker")
local Mediator = require("bridge.mediator")

-- close chann and destroy http parser
local function _clientDestroy(chann)
    local cnt = chann._cnt
    cnt.http_parser:destroy()
    chann:close()
    ThreadBroker.removeThread(chann)
end

-- client reset
local function _clientReset(chann)
    local cnt = chann._cnt
    cnt.http_parser:reset()
    cnt.fd_tbl = {}
    cnt.multipart_info = {}
    ThreadBroker.removeThread(chann)
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
    if Request.isXwwwFormUrlEncoded(req.header) or req.body:len() > 0 then
        req.post_args = UrlCore.parseQuery(req.body)
    else
        req.post_args = {}
    end
end

local function _suffix4(filename)
    if filename:len() >= 4 then
        local s = filename:find(".", filename:len() - 4, true)
        if s then
            return filename:sub(s)
        end
    end
    return ".bin"
end

-- store multipart/form-data to tmp/, put random name into multipart_info
local function _storeMultiPartData(cnt, http_tbl)
    local fd_tbl = cnt.fd_tbl
    local method = http_tbl.method
    local header = http_tbl.header
    if not Request.isMultiPartFormData(fd_tbl, method, header) then
        return false
    end
    local contents = http_tbl.contents
    local raw_data = contents and table.concat(contents) or ""
    Request.multiPartReadBody(
        fd_tbl,
        raw_data,
        function(filename, content_type, data)
            local info = cnt.multipart_info[#cnt.multipart_info]
            if data and info and info.filepath then
                FileManager.appendFile(info.filepath, data)
            elseif filename and filename:len() > 0 then
                local filepath = "tmp/" .. tostring(math.random(100000)) .. _suffix4(filename)
                cnt.multipart_info[#cnt.multipart_info + 1] = {
                    filename = filename,
                    filepath = filepath,
                    content_type = content_type
                }
            end
        end
    )
    http_tbl.contents = nil
    return true
end

-- receive client data then parse to http method, path, header, content
local function _onClientEventCallback(chann, event_name, _)
    if event_name == "event_recv" then
        local data = chann:recv()
        if data == nil then
            _clientDestroy(chann)
            return
        end
        local cnt = chann._cnt
        -- parse raw data to http protoco info
        local ret_value, state, http_tbl = cnt.http_parser:process(data)
        if ret_value < 0 then
            return
        end
        if state == HttpParser.STATE_BODY_CONTINUE and http_tbl then
            _storeMultiPartData(cnt, http_tbl)
        end
        if state == HttpParser.STATE_BODY_FINISH and http_tbl then
            local content = ""
            local multipart_info = nil -- multipart/form-data
            if _storeMultiPartData(cnt, http_tbl) then
                multipart_info = cnt.multipart_info
            elseif http_tbl.contents then
                content = table.concat(http_tbl.contents)
                http_tbl.contents = nil
            end
            -- create callback info
            local http_callback = cnt.http_callback
            if http_callback then
                -- create req
                local req = Request.new(http_tbl.method, http_tbl.url, http_tbl.header, content, multipart_info)
                req:updateRemoteIp(chann:addr().ip)
                _updateRequest(req)
                -- create response
                local option = setmetatable({}, _response_option)
                option.fn_chunked_callback = function(data)
                    chann:send(data)
                end
                local response = Response.new(option)
                local co =
                    coroutine.create(
                    function()
                        -- callback
                        http_callback(cnt.config, req, response)
                        -- finish response
                        response:finishResponse()
                        -- reset resources
                        _clientReset(chann)
                    end
                )
                -- broker take thread
                ThreadBroker.addThread(chann, co)
                coroutine.resume(co)
            end
        end
    elseif event_name == "event_disconnect" then
        _clientDestroy(chann)
    end
end

-- public interface
--

local Serv = {}

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
    -- setup env
    math.randomseed(os.time())
    FileManager.setupSandboxEnv(config)
    -- create bind
    NetCore.init()
    DnsCore.init(config)
    self.svr_tcp = NetCore.openChann("tcp")
    self.svr_tcp:listen(addr.ip, addr.port, 1024)
    self.svr_tcp:setCallback(
        function(_, event_name, accept)
            if event_name == "event_accept" and accept ~= nil then
                accept._cnt = {
                    config = config,
                    http_callback = http_callback,
                    http_parser = HttpParser.createParser("REQUEST"),
                    fd_tbl = {},
                    multipart_info = {}
                }
                accept:setCallback(_onClientEventCallback)
            end
        end
    )
    -- mnet event loop
    local poll_wait = config.poll_wait or 50
    while true do
        NetCore.poll(poll_wait)
        Mediator.servLoop()
    end
end

return Serv
