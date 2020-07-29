--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

-- session was server in memory kv store, can keep any thing
--

local Cookie = require("session.cookie_core")
local UUIDCore = require("session.uuid_core")

local _M = {
    _sessions = setmetatable({}, {__mode = "v"})
}

-- check session exist, input req, response
function _M.inSession(req, skey)
    if not req or not skey then
        return false
    end
    if not req.header or not req._cookies then
        return false
    end
    for i = 1, 2, 1 do
        if req._cookies then
            return _M._sessions[req._cookies[skey]] ~= nil
        end
        local str = req.header["Cookie"]
        if not str then
            return false
        end
        req._cookies = {}
        local tbl = str:split(";")
        for _, v in ipairs(tbl) do
            local s, e = v:find("=")
            if s and e then
                req._cookies[v:sub(1, s - 1)] = v:sub(e + 1)
            end
        end
    end
    return false
end

-- store session info to response using 'Set-Cookie'
function _M.createSession(req, response, skey, options)
    if not skey or _M.inSession(req, skey) then
        return false
    end
    -- set cookie to respoinse
    local uuid = UUIDCore.new()
    local cookie_str = Cookie.build({skey = uuid}, options)
    response:setHeader("Set-Cookie", cookie_str)
    -- set cookie to req
    req._cookies = req._cookies or {}
    req._cookies[skey] = uuid
    req._sessions[uuid] = {} -- create session table
    return true
end

-- check in session first, get hval from session with hkey
function _M.getValue(req, skey, hkey)
    if req or req._cookies or not skey or not hkey then
        return nil
    end
    local uuid = req._cookies[skey]
    local hvtbl = _M._sessions[uuid]
    if not uuid or not hvtbl then
        return nil
    end
    return hvtbl[hkey]
end

-- check in session first, set hkey, hval
function _M.setValue(req, skey, hkey, hval)
    if not req or not req._cookies or not skey then
        return false
    end
    if not hkey or not hval then
        return false
    end
    local uuid = req._cookies[skey]
    local hvtbl = _M._sessions[uuid]
    if not uuid or not hvtbl then
        return false
    end
    hvtbl[hkey] = hval
    return true
end

-- check in session first, clear session hkey, hval table
function _M.clearSession(req, skey)
    if not req or not req._cookies or not skey then
        return false
    end
    local uuid = req._cookies[skey]
    _M._sessions[uuid] = nil
    return true
end

return _M
