--
-- cincau web framework nginx config

local _ERR = ngx.ERR
local _log = ngx.log
local _logger = require("base.logger")
local _serpent = require("base.serpent")

-- redefine
table.dump = function(tbl)
    _log(_ERR, _serpent.block(tbl))
end

io.printf = function(fmt, ...)
    _log(_ERR, string.format(fmt, ...))
end

-- redefine logger printf
_logger.printf = function(level, fmt, ...)
    if _logger.validLevel(level) and type(fmt) == "string" then
        _log(_ERR, _logger._level_msg[level] .. " " .. string.format(fmt, ...))
    end
end

local config = {
    engine_type = "nginx",
    ipport = "", -- defined by config/nginx.conf
    logger = _logger,
    debug_on = false, -- debug framework, close cache
}

return config
