--
-- cincau web framework nginx config
local NGXLog = ngx.log
local Logger = require("cincau.base.logger")
local Serpent = require("cincau.base.serpent")

local type = type
local sfmt = string.format

Logger._level_msg[Logger.ERR] = ngx.ERR
Logger._level_msg[Logger.WARN] = ngx.WARN
Logger._level_msg[Logger.INFO] = ngx.INFO
Logger._level_msg[Logger.DEBUG] = ngx.DEBUG

-- redefine
table.dump = function(tbl)
    NGXLog(ngx.DEBUG, Serpent.block(tbl))
end

io.printf = function(fmt, ...)
    NGXLog(ngx.DEBUG, sfmt(fmt, ...))
end

-- redefine logger printf
Logger.printf = function(level, fmt, ...)
    if Logger.isValidLevel(level) and type(fmt) == "string" then
        NGXLog(Logger._level_msg[level], sfmt(fmt, ...))
    end
end

local config = {
    engine_type = "nginx",
    ipport = "", -- defined by config/nginx.conf

    logger = Logger,
    log_level = 3, -- debug, refers to base.logger

    debug_on = false, -- debug framework, close cache

    session = {
        outdate = 300, -- session oudated seconds
    },
    resources_max_age = 900, -- resources cache-control max-age

    dir = {
        database = "database/",
        wiki = "wiki/",
    },

    dataPath = function(dir)
        return "datas/" .. dir
    end,

    tmpPath = function(dir)
        return 'tmp/' .. dir
    end,
}

return setmetatable({}, { __index = config })
