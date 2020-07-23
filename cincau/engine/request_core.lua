--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local UrlCore = require("base.neturl")

local _M = {}
_M.__index = _M

-- path as '/hello/word?q=3&r=4'
local function _parsePath(path)
    local tbl = UrlCore.parse(path)
    return tbl.path, tbl.query
end

function _M.new(method, path, header, body)
    local req = setmetatable({}, _M)
    req.method = method
    req.path, req.query = _parsePath(path)
    req.header = header
    req.body = body or ""
    -- FIXME: not form-data, or url-encode
    if req.method == 'POST' and req.body:len() > 0 then
        req.post_args = UrlCore.parseQuery(req.body)
    else
        req.post_args = {}
    end
    return req
end

-- '/hello/word?q=3&r=4'
-- path: '/hello/word'
-- query: { q=3, r=4 }
function _M:dumpPath(logger)
    logger.err("--")
    logger.err(self.path)
    for k, v in pairs(self.query) do
        logger.err("%s\t%s", k, v)
    end
    logger.err("---")
end

return _M
