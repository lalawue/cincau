--
-- Copyright (c) 2021 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local CJson = require("cjson")
local MoocClass = require("moocscript.class")
local BasePage = require("page_core").BasePage
local FileManager = require("base.file_manager")

local type = type
local ipairs = ipairs
local concat = table.concat
local tostring = tostring

local Page = MoocClass("page_wiki", BasePage)

function Page:init(config)
    FileManager.mkdir(config.wiki_path)
end

function Page:process(config, req, response, params)
    local path_comps = self:pathCompos(req)
    local fname = path_comps[#path_comps]
    local content = ""

    if #path_comps <= 1 and fname == "sitemap" then
        self:siteMap(config, req, response, params)
        return
    end

    local path = self:fullPath(config, path_comps)

    config.logger.info("%s %s", req.method, path)

    if req.method == 'GET' then
        local data = FileManager.readFile(path)
        if data then
            content = CJson.encode({
                errcode = 0,
                text = data
            })
        else
            content = CJson.encode({
                errcode = 1,
                text = "",
            })
        end
    else
        do
            local dir = config.wiki_path
            for i=1, #path_comps - 1 do
                dir = dir .. path_comps[i] .. "/"
                FileManager.mkdir(dir)
            end
        end

        local data = CJson.decode(req.body)
        local data_len = 0

        if path and data and data.text and FileManager.saveFile(path, data.text) then
            data_len = data.text:len()
            content = CJson.encode({ errcode = 0 })
        else
            content = CJson.encode({ errcode = 1 })
        end

        config.logger.info("POST text size: %d, result: %s", data_len, content)
    end
    response:setHeader("Content-Type", "application/json")
    -- append body as chunked data
    response:appendBody(content)
end

function Page:siteMap(config, req, response, params)
    local tbl = FileManager.travelDir(config.wiki_path, { file = true, directory = true })
    local out = {}
    self:travelDirTable("", config.wiki_path, tbl, out)
    local text = concat(out, '\n')
    config.logger.info(text)
    response:setHeader("Content-Type", "application/json")
    response:appendBody(CJson.encode({
        errcode = 0,
        text = text,
    }))
end

function Page:travelDirTable(indent, path, tbl, out)
    for i, v in ipairs(tbl) do
        if i > 1 then
            if type(v) == "table" then
                out[#out + 1] = indent .. "- **" .. v[1] .. '/**'
                self:travelDirTable(indent .. "  ", path .. v[1] .. '/', v, out)
            elseif v:sub(1, 1) ~= '.' then
                out[#out + 1] = indent .. "- [" .. v .. '](' .. path .. v .. ')'
            end
        end
    end
end

function Page:pathCompos(req)
    if req.query.f then
        local tbl = (req.query.d or ""):split("/")
        if #tbl > 0 and tbl[#tbl]:len() > 0 then
            tbl[#tbl + 1] = req.query.f
        else
            tbl[#tbl] = req.query.f
        end
        return tbl
    else
        return {}
    end
end

function Page:fullPath(config, path_comps)
    return config.wiki_path .. concat(path_comps, "/") .. ".md"
end

return Page