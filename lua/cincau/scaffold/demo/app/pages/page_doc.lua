--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local Render = require("cincau.view_core")
local Model = require("app.models.model_doc")
local MoocClass = require("moocscript.class")
local BasePage = require("cincau.page_core").BasePage

local Page = MoocClass("page_doc", BasePage)

-- only run once
function Page:init(config)
    Model:loadModel()
end

-- output param.name defined in router.lua
function Page:process(config, req, response, params)
    -- set header before appendBody
    response:setHeader("Content-Type", "text/html")
    -- render page content
    local page_content = Render:render(self:templteHTML(), {
        css_path = "/css/doc.css",
        page_title = self:upperCaseFirstChar(params.name) .. " documents",
        page_content = Model:getParagraphs()
    })

    -- append body as chunked data
    response:appendBody(page_content)
end

function Page:upperCaseFirstChar(str)
    return str:sub(1, 1):upper() .. str:sub(2)
end

-- using default tags
function Page:templteHTML()
    return
[[<html>
{(app/templates/head.html)}
<body>
    <h1>{{ page_title }}</h1>
    <hr/>
    {* page_content *}
</body>
</html>]]
end

return Page