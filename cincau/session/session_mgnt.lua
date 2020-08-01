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
local FifoNew = require("base.fifo")

local _M = {
    _sessions = setmetatable({}, {__mode = "v"}),
    _fifo = FifoNew()
}

-- check session exist, input req, response
function _M.inSession(req, skey)
    if not req or not req.header or not skey then
        return false
    end
    for i = 1, 2, 1 do
        if req._cookies then
            local uuid = req._cookies[skey]
            local info = uuid and _M._sessions[uuid] or nil
            if info and info._time then
                info._time.visited = os.time()
            end
            return (info and true) or false
        end
        local cookie_str = req.header["Cookie"]
        if not cookie_str then
            return false
        end
        req._cookies = {}
        local tbl = cookie_str:split("; ")
        for _, v in ipairs(tbl) do
            local s, e = v:find("=[^=]")
            if s and e then
                req._cookies[v:sub(1, s - 1)] = v:sub(e)
            end
        end
    end
    return false
end

--[[ store session info to response using 'Set-Cookie'
local options = {
	max_age = 3600,
	domain = ".example.com",
	path = "/",
	expires = time,
	http_only = true,
	secure = true
}
local expected =
	"foo=bar; Max-Age=3600; Domain=.example.com; " ..
	"Path=/; Expires=Wed, 23 Apr 2014 13:01:14 GMT; " ..
	"HttpOnly; Secure
]]
function _M.createSession(req, response, skey, options)
    if not req or not response or not skey or _M.inSession(req, skey) then
        return false
    end
    -- set cookie to respoinse
    local uuid = UUIDCore.new()
    local cookie_str = Cookie.build({[skey] = uuid}, options)
    response:setHeader("Set-Cookie", cookie_str)
    -- set cookie to req
    req._cookies[skey] = uuid
    -- create session table
    local now = os.time()
    local tm = {
        created = now,
        visited = now,
        uuid = uuid
    }
    _M._sessions[uuid] = {
        _time = tm
    }
    _M._fifo:push(tm)
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
    hvtbl._time.visited = os.time()
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
    hvtbl._time.visited = os.time()
    return true
end

-- check in session first, clear session hkey, hval table
function _M.clearSession(req, skey)
    if not req or not req._cookies or not skey then
        return false
    end
    local uuid = req._cookies[skey]
    local hvtbl = _M._sessions[uuid]
    if hvtbl then
        hvtbl._time.created = 0
        hvtbl._time.visited = 0
        _M._sessions[uuid] = nil
    end
    return true
end

-- clear outdate session
function _M.clearOutdate(seconds)
    local now = os.time()
    repeat
        local tm = _M._fifo:peek()
        if not tm then
            break
        end
        _M._fifo:pop()
        if now - tm.created >= seconds then
            -- visited in this circle, make it visible in next circle
            if tm.visited ~= tm.created then
                tm.visited = now
                tm.created = now
                _M._fifo:push(tm)
            else
                _M._sessions[tm.uuid] = nil
            end
        else
            break
        end
    until tm == nil
end

return _M
