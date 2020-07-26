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

-- response option
local _response_option = {
    en_output_header = false, -- construct header by nginx
    en_chunked_length = false, -- chunked body length by nginx
    fn_chunked_callback = function(data)
        ngx.say(data)
    end,
    fn_set_header = function(key, value)
        ngx.header[key] = value
    end,
    fn_set_status = function(status_code)
        ngx.status = status_code
    end
}

local function _updateRequest(req, is_multipart_formdata)
    -- enough for x-www-form-urlencoded or body kv
    if req.method == "POST" and not is_multipart_formdata then
        ngx.req.read_body()
        req.post_args = ngx.req.get_post_args()
    else
        req.post_args = {}
    end
end

-- run server, http_callback(config, req, response)
function Serv:run(config, http_callback)
    local fd_tbl = {}
    local multipart_info = nil
    -- create req
    local nreq = ngx.req
    local nvar = ngx.var
    local method = nreq.get_method()
    local header = nreq.get_headers()
    local is_multipart_formdata = Request.isMultiPartFormData(fd_tbl, method, header)
    -- fill fake multipart info, nginx use another way to upload binary files
    if is_multipart_formdata then
        multipart_info = {
            filename = "nginx upload howto",
            content_type = "application/html",
            filepath = "https://www.nginx.com/resources/wiki/modules/upload/"
        }
    end
    local data = is_multipart_formdata and "" or nreq.get_body_data()
    local req = Request.new(method, nvar.request_uri, header, data, multipart_info)
    _updateRequest(req, is_multipart_formdata)
    -- create response
    local response = Response.new(_response_option)
    -- callback
    http_callback(config, req, response)
    -- finish response
    response:finishResponse()
end

return Serv
