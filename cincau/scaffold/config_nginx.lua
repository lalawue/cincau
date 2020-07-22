--
-- cincau web framework nginx config

local ngx = ngx or {}
local _logger = require("base.logger")
local _serpent = require("base.serpent")

-- redefine
table.dump = function(tbl)
    ngx.log(ngx.ERR, _serpent.block(tbl))
end

io.printf = function(fmt, ...)
    ngx.log(ngx.ERR, string.format(fmt, ...))
end

-- redefine logger printf
_logger.printf = function(level, fmt, ...)
    if _logger.validLevel(level) and type(fmt) == "string" then
        ngx.log(ngx.ERR, _logger._level_msg[level] .. " " .. string.format(fmt, ...))
    end
end

return {
    ipport = "", -- defined by config/nginx.conf
    logger = _logger
}
