--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local ngx = ngx or {}
local Request = require("engine.request_core")
local Response = require("engine.response_core")

-- Serv instance
local Serv = {}

local _option = {
    en_output_header = false, -- construct header by nginx
    en_chunked_length = false, -- chunked body length by nginx
    fn_chunked_callback = function(data)
        ngx.say(data)
    end,
    fn_set_header = function (key, value)
        ngx.header[key] = value
    end,
    fn_set_status = function(status_code)
        ngx.status = status_code
    end
}

-- run server, http_callback(config, req, response)
function Serv:run(config, http_callback)
    -- create req
    local nreq = ngx.req
    local nvar = ngx.var
    local req = Request.new(nreq.get_method(), nvar.request_uri, nreq.get_headers(), nreq.get_body_data())
    -- create response
    local response = Response.new(_option)
    -- callback
    http_callback(config, req, response)
    -- finish response
    response:finishResponse()
end

return Serv
