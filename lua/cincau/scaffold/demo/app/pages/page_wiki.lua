--
-- Copyright (c) 2021 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local Render = require("view_core")
local MoocClass = require("moocscript.class")
local BasePage = require("page_core").BasePage
local FileManager = require("base.file_manager")

local Page = MoocClass("page_wiki", BasePage)

-- output index page
function Page:process(config, req, response, params)
    if req.method == 'GET' then
        -- set header before appendBody
        response:setHeader("Content-Type", "text/html")
        -- render page content
        local page_content = Render:render(self.htmlSpec, {
        })
        -- append body as chunked data
        response:appendBody(page_content)
    end
end

-- using default tags
function Page:htmlSpec()
    return {
        html {
            doctype "html",
            head {
                meta {'[charset=utf-8]'},
                meta {'[name=viewport][content=width=device-width, initial-scale=1]'},
                link {'[rel=stylesheet][href=/css/doc.css]'},
                style {[[.editor-toolbar {
                    background: #fff;
                }
                button {
                    padding: 10px 15px 12px 15px;
                    border-radius: 8px;
                }
                h1,h2,h3,h4,h5,h6,p,ul,pre {
                    margin-left: 0;
                    margin-right: 0;
                }]]},
            },
            body {
                div {{'[class=fixed top-0]'},
                div {{'[id=btn_left][class=fixed left-0 mt2 ml2]'},
                    button {{"[onclick=window.location.href='/';]"}, "Home"},
                    br,
                    button {{"[onclick=window.location.href='/wiki';][class=mt1]"}, "Index"},
                },
                    div {{'[id=btn_right][class=fixed right-0 mt2 mr2]'}},
                },
                div {{'[class=mx-auto]'},
                    h1 {{'[id=wiki_title][class=center]'},
                    }
                },
                hr,
                br,
                div {{'[id=main_container][class=lg-col-8 md-col-10 mx-auto]'},
                },
                link { '[rel=stylesheet][href=https://cdn.jsdelivr.net/simplemde/latest/simplemde.min.css]'},
                link {'[rel=stylesheet][href=https://unpkg.com/basscss@8.0.2/css/basscss.min.css]'},
                script {{'[src=https://cdn.jsdelivr.net/simplemde/latest/simplemde.min.js]'}},
                script {{'[src=https://unpkg.com/htm@3.1.0/dist/htm.js]'}},
                script {{'[src=https://unpkg.com/mithril@2.0.4/mithril.min.js]'}},
                script {{'[src=/js/wiki_cnt.js]'}},
            }
        }
    }
end

return Page