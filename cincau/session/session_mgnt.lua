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
local List = require("base.ffi_list")

local _M = {
    _sessions = {},
    _lst = List.new()
}

-- update time struct, push to last
local function _updateTime(lst, tm)
    tm.time = os.time()
    lst:remove(tm)
    lst:pushl(tm)
end

-- check session exist, from req
function _M.inSession(req, skey)
    if not req or not skey then
        return false
    end
    local uuid = req.cookies[skey]
    local sinfo = _M._sessions[uuid]
    if sinfo and sinfo.tm then
        _updateTime(_M._lst, sinfo.tm)
    end
    return (sinfo and true) or false
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
        time = now,
        uuid = uuid
    }
    _M._sessions[uuid] = {
        tm = tm
    }
    _M._lst:pushl(tm)
    return true
end

-- check in session first, get hval from session with hkey
function _M.getValue(req, skey, hkey)
    if not req or not skey or not hkey then
        return nil
    end
    local uuid = req.cookies[skey]
    local sinfo = _M._sessions[uuid]
    if not uuid or not sinfo then
        return nil
    end
    _updateTime(_M._lst, sinfo.tm)
    return sinfo[hkey]
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
    local sinfo = _M._sessions[uuid]
    if not uuid or not sinfo then
        return false
    end
    sinfo[hkey] = hval
    _updateTime(_M._lst, sinfo.tm)
    return true
end

-- check in session first, clear session hkey, hval table
function _M.clearSession(req, skey)
    if not req or not skey then
        return false
    end
    local uuid = req.cookies[skey]
    local sinfo = _M._sessions[uuid]
    if uuid and sinfo then
        _M._lst:remove(sinfo.tm)
        _M._sessions[uuid] = nil
    end
    return true
end

-- clear outdate session
function _M.clearOutdate(seconds)
    local now = os.time()
    repeat
        local tm = _M._lst:first()
        if not tm or now - tm.time < seconds then
            break
        end
        _M._lst:popf(tm)
        _M._sessions[tm.uuid] = nil
    until tm == nil
end

return _M
