--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local M = {
    _level = 2, -- default info level
    ERR = 0,
    WARN = 1,
    INFO = 2,
    DEBUG = 3
}

local _level_msg = {
    [M.ERR] = "[ERR]",
    [M.WARN] = "[WARN]",
    [M.INFO] = "[INFO]",
    [M.DEBUG] = "[DEBUG]"
}

function M.setLevel(level)
    level = math.max(M.ERR, level)
    level = math.min(M.DEBUG, level)
    M._level = level
end

function M.printf(level, fmt, ...)
    if level < M.ERR or level > M._level or type(fmt) ~= "string" then
        return
    end
    print(_level_msg[level] .. " " .. string.format(fmt, ...))
end

function M.err(fmt, ...)
    M.printf(M.ERR, fmt, ...)
end

function M.warn(fmt, ...)
    M.printf(M.WARN, fmt, ...)
end

function M.info(fmt, ...)
    M.printf(M.INFO, fmt, ...)
end

function M.debug(fmt, ...)
    M.printf(M.DEBUG, fmt, ...)
end

return M
