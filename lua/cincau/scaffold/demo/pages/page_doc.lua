--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local Render = require("view_core")
local Model = require("models.model_doc")
local MoocClass = require("moocscript.class")
local BasePage = require("page_core").BasePage

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
    local page_content = Render:render(self.pageContent, {
        css_path = "/styles/doc.css",
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
function Page:pageContent()
    return {
        html {
            include "app/templates/head_tpl.lua",
            body {
                h1 { page_title },
                hr,
                page_content,                
            }
        }
    }
end

return Page