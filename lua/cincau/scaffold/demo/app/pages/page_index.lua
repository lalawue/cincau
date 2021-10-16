--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local Render = require("view_core")
local MoocClass = require("moocscript.class")
local BasePage = require("page_core").BasePage

local Page = MoocClass("page_index", BasePage)

-- output index page
function Page:process(config, req, response, params)
    -- set header before appendBody
    response:setHeader("Content-Type", "text/html")
    -- render page content
    local page_content = Render:render(self:templateHTML(), {
        css_path = "/css/index.css",
        page_title = "Cincau web framework",
        page_features = {"minimalist", "fast", "high configurable", "for LuaJIT", "on mnet or openresty (nginx)"},
    })
    -- append body as chunked data
    response:appendBody(page_content)
end

-- using default tags
function Page:templateHTML()
    return
[[<html>
{(app/templates/head.html)}
<body>
    <h1>{{ page_title }}</h1>
    <ul>
    {% for _, v in ipairs(page_features) do %}
        <li>{*v*}</li>
    {% end %}
    </ul>
    <footer>
        get <a href="doc/cincau">doc</a>, try <a href="playground">playground</a>,
        <a href="wiki">wiki</a>, or visit <a href="https://github.com/lalawue/cincau">github</a>.
    </footer>
</body>
</html>]]
end

return Page