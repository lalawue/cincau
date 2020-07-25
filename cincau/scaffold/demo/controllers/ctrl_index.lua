--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local render = require("view_core")
local _M = require("controller_core").newInstance()

-- output index page
function _M:process(config, req, response, params)
    -- set header before appendBody
    response:setHeader("Content-Type", "text/html")
    -- render page content
    local page_content =
        render:render(
        "view_index",
        {
            title = "Cincau web framework",
            features = {"minimalist", "fast", "high configurable", "for LuaJIT", "on mnet or openresty (nginx)"},
            footer = 'get <a href="doc/cincau">documents</a>, try <a href="playground">playground</a>, or visited in <a href="https://github.com/lalawue/cincau">github</a>.'
        },
        config -- for debug purpose
    )
    -- append body as chunked data
    response:appendBody(page_content)
end

return _M
