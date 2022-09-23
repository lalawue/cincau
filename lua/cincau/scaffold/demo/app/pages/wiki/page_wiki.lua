--
-- Copyright (c) 2021 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local Render = require("cincau.view_core")
local MoocLib = require("moocscript.class")
local BasePage = require("cincau.page_core").BasePage
local FileManager = require("cincau.base.file_manager")

local Page = MoocLib.newMoocClass("page_wiki", BasePage)

-- output index page
function Page:process(config, req, response, params)
    if req.method == 'GET' then
        -- set header before appendBody
        response:setHeader("Content-Type", "text/html")
        -- render page content
        local page_content = Render:render(self:templteHTML(), {
        })
        -- append body as chunked data
        response:appendBody(page_content)
    end
end

-- using default tags
function Page:templteHTML()
    return
[[<!DOCTYPE html>
  <html>
    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width initial-scale=1" />
        <link rel="stylesheet" type="text/css" href="/css/wiki.css" />
        <title>Cincau wiki</title>
        <style>
        .editor-toolbar {
            background: #fff;
        }
        button {
            padding: 10px 15px 12px 15px;
            border-radius: 8px;
        }
        h1,h2,h3,h4,h5,h6,p,ul,pre {
            margin-left: 0;
            margin-right: 0;
        }
        </style>
        <script>
        function wikiMovePage(path) {
            let npath = prompt("rename file path to:", path);
            if (npath == null || npath == "" || path == npath) {
                return
            }
            const p = path.lastIndexOf('/')
            const d = path.substring(0, p)
            const f = path.substring(p+1)
            const np = npath.lastIndexOf('/')
            const nd = npath.substring(0, np)
            const nf = npath.substring(np+1)
            if (p>0 && np>0) {
                m.request("/wikidata?d="+d+"&f="+f+"&md="+nd+"&mf="+nf)
                .then(function(ret){
                    if (ret.errcode == 0) {
                    location.reload();
                    }
                })
            }
        }
        </script>
    </head>
    <body>
        <div class="fixed top-0">
            <div id="btn_left" class="fixed left-0 mt2 ml2">
                <button onclick="window.location.href='/';">Home</button><br/>
                <button onclick="window.location.href='/wiki';" class="mt1">Index</button>
            </div>
            <div id="btn_right" class="fixed right-0 mt2 mr2">
            </div>
        </div>
        <div class="mx-auto">
            <h1 id="wiki_title" class="center"></h1>
        </div>
        <hr/>
        <br/>
        <div id="main_container" class="lg-col-8 md-col-10 mx-auto">
        </div>
        <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/simplemde/latest/simplemde.min.css" />
        <link rel="stylesheet" type="text/css" href="https://unpkg.com/basscss@8.0.2/css/basscss.min.css" />
        <script src="https://cdn.jsdelivr.net/simplemde/latest/simplemde.min.js"></script>
        <script src="https://unpkg.com/htm@3.1.0/dist/htm.js"></script>
        <script src="https://unpkg.com/mithril@2.0.4/mithril.min.js"></script>
        <script src="/js/wiki_cnt.js"></script>
    </body>
</html>]]
end

return Page