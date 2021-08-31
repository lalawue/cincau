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
    local features = {"minimalist", "fast", "high configurable", "for LuaJIT", "on mnet or openresty (nginx)"}
    local page_content = Render:render(self.pageContent, {
        css_path = "/styles/index.css",
        page_title = "Cincau web framework",
        page_features = table.ireduce(features, "", function(total, i, value)
            return total .. '<li>' .. value .. '</li>\n'
        end),
        page_footer = 'get <a href="doc/cincau">documents</a>, try <a href="playground">playground</a>, or visited in <a href="https://github.com/lalawue/cincau">github</a>.',
    })
    -- append body as chunked data
    response:appendBody(page_content)
end

-- using default tags
function Page:pageContent()
    return {
        html {
            include "app/templates/head_tpl.lua",
            body {
                h1 { page_title },
                ul {
                    page_features,
                },
                div {
                    { class = "footer" },
                    page_footer,
                }
            }
        }
    }
end

return Page