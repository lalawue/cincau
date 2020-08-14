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
local RBTree = require("lrbtree")

local _M = {
    _sessions = {},
    _rbtree = RBTree.new(
        function(tma, tmb)
            return tma.created - tmb.created
        end
    )
}

-- check session exist, from req
function _M.inSession(req, skey)
    if not req or not skey then
        return false
    end
    local uuid = req.cookies[skey]
    local info = _M._sessions[uuid]
    if info and info._tm then
        info._tm.visited = os.time()
    end
    return (info and true) or false
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
    if not response or _M.inSession(req, skey) then
        return false
    end
    -- set cookie to respoinse
    local uuid = UUIDCore.new()
    local cookie_str = Cookie.build({[skey] = uuid}, options)
    response:setHeader("Set-Cookie", cookie_str)
    -- set cookie to req
    req.cookies[skey] = uuid
    -- create session table
    local now = os.time()
    local tm = {
        created = now,
        visited = now,
        uuid = uuid
    }
    _M._sessions[uuid] = {
        _tm = tm
    }
    _M._rbtree:insert(tm)
    return true
end

-- check in session first, get hval from session with hkey
function _M.getValue(req, skey, hkey)
    if not req or not skey or not hkey then
        return nil
    end
    local uuid = req.cookies[skey]
    local hvtbl = _M._sessions[uuid]
    if not uuid or not hvtbl then
        return nil
    end
    hvtbl._tm.visited = os.time()
    return hvtbl[hkey]
end

-- check in session first, set hkey, hval
function _M.setValue(req, skey, hkey, hval)
    if not req or not skey then
        return false
    end
    if not hkey or not hval then
        return false
    end
    local uuid = req.cookies[skey]
    local hvtbl = _M._sessions[uuid]
    if not uuid or not hvtbl then
        return false
    end
    hvtbl[hkey] = hval
    hvtbl._tm.visited = os.time()
    return true
end

-- check in session first, clear session hkey, hval table
function _M.clearSession(req, skey)
    if not req or not skey then
        return false
    end
    local uuid = req.cookies[skey]
    local hvtbl = _M._sessions[uuid]
    if uuid and hvtbl then
        _M._rbtree:delete(hvtbl._tm)
        _M._sessions[uuid] = nil
    end
    return true
end

-- clear outdate session
function _M.clearOutdate(seconds)
    local now = os.time()
    repeat
        local tm = _M._rbtree:first()
        if not tm then
            break
        end
        _M._rbtree:delete(tm)
        if now - tm.created >= seconds then
            -- visited in this circle, make it visible in next circle
            if tm.visited ~= tm.created then
                tm.visited = now
                tm.created = now
                _M._rbtree:insert(tm)
            else
                _M._sessions[tm.uuid] = nil
            end
        else
            break
        end
    until tm == nil
end

return _M
