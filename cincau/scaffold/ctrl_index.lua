--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local _M = require("controller_core").instance()

-- output index
function _M:process(config, req, response, params)
    local logger = config.logger
    logger.err("match root controller, %s, %s, %s, %s", config, req, response, params)
    response:setHeader("Content-Type", "text/plain") -- set header before appendBody
    response:appendBody("hello cincau ~")
end

return _M
