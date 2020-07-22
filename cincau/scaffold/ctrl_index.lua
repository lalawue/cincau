--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local render = require("view_core")
local _M = require("controller_core").newInstance()

-- register using template
render:register(
    {
        "view_index"
    }
)

-- output index page
function _M:process(config, req, response, params)
    response:setHeader("Content-Type", "text/plain") -- set header before appendBody
    local page = render:render("view_index", {  name = "cincao",
    features = { "mini", "fast", "high configurable"}})
    response:appendBody(page)
end

return _M
