--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local _M = require("controller_core").instance()

-- output hello
function _M:process(config, req, response, params)
    local logger = config.logger
    logger.err("match hello controller, name param: %s", params.name)
    response:setHeader("Content-Type", "text/plain")
    response:appendBody("hello cincau world ~")
end

return _M
