--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local ngx = ngx or {}
local Request = require("engine.request_core")
--local Logger = require("config").logger

local Serv = {}

-- run server, http_callback(config, req, response)
function Serv:run(config, http_callback)
    -- create req
    local nreq = ngx.req
    local nvar = ngx.var
    local req = Request.new(nreq.get_method(), nvar.request_uri, nreq.get_headers(), nreq.get_body_data())
    --req:dumpPath(config.logger)
    -- create response
    local response = {
        header = {
            ["X-Powered-By"] = "cincau framework"
        },
        body = ""
    }
    -- callback
    http_callback(config, req, response)
    -- FIXME: construct response to client
    for k, v in pairs(response.header) do
        ngx.header[k] = v
    end
    if string.len(response.body) > 0 then
        ngx.say(response.body)
    end
end

return Serv
