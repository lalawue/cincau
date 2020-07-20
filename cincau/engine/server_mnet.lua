--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local NetCore = require("vendor.lib.ffi_mnet")
local HttpParser = require("vendor.lib.ffi_hyperparser")
local Logger = require("config.proj_config").logger

local Serv = {}

-- close chann and destroy http parser
local function _clientDestroy(chann)
    chann:close()
    chann._http_parser:destroy()
    chann._left_data = ""
    chann._router = nil
end

-- receive client data then parse to http method, path, header, content
local function _onClientEventCallback(chann, event_name, _)
    if event_name == "event_recv" then
        local data = chann:recv()
        if data == nil then
            _clientDestroy(chann)
            return
        end
        chann._left_data = chann._left_data .. data
        local ret_value, state, http_tbl = chann._http_parser:process(chann._left_data)
        if ret_value < 0 then
            return
        end
        if ret_value > 0 and ret_value < data:len() then
            chann._left_data = data:sub(ret_value + 1)
        end
        if state == HttpParser.STATE_BODY_FINISH and http_tbl then
            local content = ""
            if http_tbl.contents then
                content = table.concat(http_tbl.contents)
                http_tbl.contents = nil
            end
            if chann._http_callback then
                local req = {
                    method = http_tbl.method,
                    path = http_tbl.url,
                    header = http_tbl.header,
                    body = content or ""
                }
                local response = {
                    header = {
                        ["X-Powered-By"] = "cincau framework"
                    },
                    body = ""
                }
                chann._http_callback(req, response)
                -- FIXME: construct response to client
                response.header["Server"] = "mnet"
                response.header["Content-Type"] = "text/plain"
                response.header["Transfer-Encoding"] = "chunked"
                local output_content = "HTTP/1.1 200 OK\r\n"
                for k, v in pairs(response.header) do
                    output_content = output_content .. string.format("%s: %s\r\n", k, v)
                end
                output_content = output_content .. "\r\n"
                -- body
                output_content = output_content .. string.format("%X", string.len(response.body)) .. "\r\n"
                output_content = output_content .. response.body .. "\r\n"
                output_content = output_content .. "0\r\n\r\n"
                io.write(output_content)
                -- send
                chann:send(output_content)
            end
        end
    elseif event_name == "event_disconnect" then
        _clientDestroy(chann)
    end
end

-- run server, http_callback(req, response)
function Serv:run(ipport, http_callback)
    local addr = NetCore.parseIpPort(ipport)
    if type(addr.ip) ~= "string" or type(addr.port) ~= "number" then
        Logger.err("invalid ipport")
        return
    else
        Logger.info("listen on %s:%d", addr.ip, addr.port)
    end
    NetCore.init()
    self.svr_tcp = NetCore.openChann("tcp")
    self.svr_tcp:listen(addr.ip, addr.port, 1024)
    self.svr_tcp:setCallback(
        function(_, event_name, accept)
            if event_name == "event_accept" and accept ~= nil then
                accept._left_data = ""
                accept._http_callback = http_callback
                accept._http_parser = HttpParser.createParser("REQUEST")
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
