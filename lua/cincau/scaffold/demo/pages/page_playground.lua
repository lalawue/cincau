--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local Render = require("view_core")
local Mediator = require("bridge.mediator")
local MoocClass = require("moocscript.class")
local Model = require("models.model_playground")
local PageBase = require("page_core").Controller

local Page = MoocClass("page_playground", PageBase)

function Page:init(config)
    Model:loadModel(config)
end

    -- fetch req multipart info to multipart_info table
function Page:_processMultiPartInfo(req, multipart_info)
    for _, info in ipairs(req.multipart_info) do
        multipart_info[#multipart_info + 1] = {
            string.format("name: %s", info.filename),
            string.format("path: %s", info.filepath),
            string.format("content_type: %s", info.content_type)
        }
    end
end

function Page:_processInputDeleteModel(post_args)
    local is_input = false
    -- if body key=value
    for k, v in pairs(post_args) do
        if k == "input" then
            is_input = true
            Model:pushInput(v)
        elseif k == "delete" then
            is_input = true
            Model:deleteInput(v)
        end
    end
    return is_input
end

    -- process x-www-form-urlencoded as k1=v1&k2=v2
function Page:_processUrlEncodedData(post_args)
    local is_input = false
    local enc1, enc2 = nil, nil
    for k, v in pairs(post_args) do
        if k == "enc1" then
            enc1 = v
            is_input = true
        elseif k == "enc2" then
            enc2 = v
            is_input = true
        end
    end
    if type(enc1) == "string" and type(enc2) == "string" and enc1:len() > 0 and enc2:len() > 0 then
        Model:pushEncodes(enc1, enc2)
    end
    return is_input
end

    -- query domain
function Page:_processQueryDomain(post_args, dns_query)
    for k, domain in pairs(post_args) do
        if k == "domain" then
            dns_query[1] = domain
            dns_query[2] = Mediator.queryDomain(domain)
            return true
        end
    end
    return false
end

    -- show query dns entry on page
function Page:_getDnsShowBlock(config)
    if config.engine_type ~= "mnet" then
        return ""
    end
    return [[
        <div class="line">
            <p class="cell">] &nbsp; try query domain: &nbsp;</p>
            <form class="cell" action="" method="POST">
                <input type="text" name="domain" placeholder="www.baidu.com" />
                <input type="submit" value="submit" />
            </form>
        </div>
        <br />]]
end

    -- show upload multipart/form-data example
function Page:_getMultipartShowBlock(config)
    if config.engine_type ~= "mnet" then
        return ""
    end
    return [[
        <div class="line">
            <p class="cell">] &nbsp; try upload multipart/form-data: &nbsp;</p>
            <form class="cell" action="" method="POST" enctype="multipart/form-data">
                <input type="file" name="file1" />
                <input type="file" name="file2" />
                <input type="submit" value = "submit" />
            </form>
        </div>
        <br />]]
end

function Page:process(config, req, response, params)
    local multipart_info = {}
    local dns_query = {}
    -- set header before appendBody
    response:setHeader("Content-Type", "text/html")
    --
    if req.multipart_info then
        self:_processMultiPartInfo(req, multipart_info)
    elseif req.method == "POST" and not table.isempty(req.post_args) then
        if self:_processInputDeleteModel(req.post_args) then
            -- process POST input/delete
        elseif self:_processUrlEncodedData(req.post_args) then
            -- process POST enc1/enc2
        elseif self:_processQueryDomain(req.post_args, dns_query) then
            -- proces POS domain
        end
    end

    -- render page content
    local page_content = Render:render(self._htmlSpec, {
        css_path = "/styles/playground.css",
        script_content = [[if ( window.history.replaceState ) {
            window.history.replaceState( null, null, window.location.href );
        }]],
        engine_type = config.engine_type,
        multipart_show_block = self:_getMultipartShowBlock(config),
        dns_show_block = self:_getDnsShowBlock(config),
        dns_query_result = function()
            if dns_query[1] and dns_query[2] then
                return [[<div class="line"><li>domain: ]] ..
                                tostring(dns_query[1]) ..
                                [[</li><li>ip: ]] .. 
                                tostring(dns_query[2]) ..
                                [[</li></div>]]
            else
                return ""
            end
        end,
        input_result = table.ireduce(Model:allInputs(), "", function(total, i, value)
            return total .. [[<div class="line"><li class="cell">]] ..
                   tostring(i) ..
                   [[. text: ]] ..
                   value ..
                   [[</li>&nbsp;&nbsp;&nbsp;&nbsp;<form class="cell" action="" method="POST">
                   <input type="hidden" name="delete" value="]] ..
                   value ..
                   [[" /><input type="submit" value="delete" /></form></div>]]
        end),
        encodes_result = table.ireduce(Model:allEncodes(), "", function(total, i, value)
            return total .. '<div class="line"><li class="cell"> ' ..
                   tostring(i) ..
                   '. text: ' ..
                   value[1] ..
                   ', '
                   ..
                   value[2] ..
                   '</li></div>'
        end),
        multipart_info = table.ireduce(multipart_info, "", function(total, i, item)
            return total .. table.ireduce(item, "", function(total, i, line)
                return total .. '<div class="line"><li class="cell">' .. line .. '</li></div>'
            end)
        end),
    })

    -- append body as chunked data
    response:appendBody(page_content)
end

-- html content
function Page:_htmlSpec()
    return {
        html {
            include "app/templates/head_tpl.lua",
            body {
                h1 { page_title },
                hr,
                p {
                    "engine type: ",
                    engine_type
                },
                div {{ class = "line" },
                    p {{ class = "cell" },
                        "] &nbsp; try POST text in db: &nbsp;",
                    },
                    form {{ class="cell", action="", method="POST" },
                        input { type="text", name="input", placeholder="" },
                        input { type="submit", value="submit" }
                    },
                },
                br,
                div {{ class = "line" },
                    p {{class = "cell"},
                        "] &nbsp; try 'application/x-www-form-urlencoded' text: &nbsp;",
                    },
                    form {{ class="cell", action="", method="POST", enctype="application/x-www-form-urlencoded" },
                        input { type="text", name="enc1" },
                        input { type="text", name="enc2" },
                        input { type="submit", value="submit" }
                    }
                },
                br,
                multipart_show_block,
                dns_show_block,
                hr,
                ul {
                    dns_query_result,
                    input_result,
                    encodes_result,
                    multipart_info,
                }
            }
        }
    }
end

return Page
