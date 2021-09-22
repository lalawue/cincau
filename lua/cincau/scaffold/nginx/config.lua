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

return {
    engine_type = "nginx",
    ipport = "", -- defined by config/nginx.conf
    logger = Logger,
    debug_on = false, -- debug framework, close cache
    session_outdate = 300, -- session oudated seconds
    db_path = "datas/database/", -- database dir
    wiki_path = "datas/wiki/", -- wiki dir
}
