--
-- cincau web framework nginx config
local ERR = ngx.ERR
local Log = ngx.log
local Logger = require("base.logger")
local Serpent = require("base.serpent")

-- redefine
table.dump = function(tbl)
    Log(ERR, Serpent.block(tbl))
end

io.printf = function(fmt, ...)
    Log(ERR, string.format(fmt, ...))
end

-- redefine logger printf
Logger.printf = function(level, fmt, ...)
    if Logger.validLevel(level) and type(fmt) == "string" then
        Log(ERR, Logger._level_msg[level] .. " " .. string.format(fmt, ...))
    end
end

local config = {
    engine_type = "nginx",
    ipport = "", -- defined by config/nginx.conf
    logger = Logger,
    debug_on = false, -- debug framework, close cache
    session_outdate = 300, -- session oudated seconds
    resources_max_age = 900, -- resources cache-control max-age
    dir = {
        database = "database/",
        wiki = "wiki/",
    },
}

config.dataPath = function(dir)
    return "datas/" .. dir
end

return config
