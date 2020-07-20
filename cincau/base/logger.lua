--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local _M = {
    _level = 2, -- default info level
    ERR = 0,
    WARN = 1,
    INFO = 2,
    DEBUG = 3
}

_M._level_msg = {
    [_M.ERR] = "[ERR]",
    [_M.WARN] = "[WARN]",
    [_M.INFO] = "[INFO]",
    [_M.DEBUG] = "[DEBUG]"
}

function _M.setLevel(level)
    level = math.max(_M.ERR, level)
    level = math.min(_M.DEBUG, level)
    _M._level = level
end

function _M.validLevel(level)
    if level < _M.ERR or level > _M._level  then
        return false
    end
    return true
end

function _M.printf(level, fmt, ...)
    if _M.validLevel(level) and type(fmt) == "string" then
        print(_M._level_msg[level] .. " " .. string.format(fmt, ...))
    end
end

function _M.err(fmt, ...)
    _M.printf(_M.ERR, fmt, ...)
end

function _M.warn(fmt, ...)
    _M.printf(_M.WARN, fmt, ...)
end

function _M.info(fmt, ...)
    _M.printf(_M.INFO, fmt, ...)
end

function _M.debug(fmt, ...)
    _M.printf(_M.DEBUG, fmt, ...)
end

return _M
