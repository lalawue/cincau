--
-- Copyright (c) 2021 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local CJson = require("cjson")
local MoocLib = require("moocscript.class")
local BasePage = require("cincau.page_core").BasePage
local FileManager = require("cincau.base.file_manager")

local type = type
local ipairs = ipairs
local concat = table.concat
local tostring = tostring
local execute = os.execute

local Page = MoocLib.newMoocClass("page_wiki", BasePage)

function Page:init(config)
    self.wiki_path = config.dataPath(config.dir.wiki)
    FileManager.mkdir(self.wiki_path)
end

function Page:process(config, req, response, params)
    local path_comps = self:pathCompos(req.query.d, req.query.f)
    local fname = path_comps[#path_comps]
    local content = ""

    -- invalid path as having ".." in path
    if #path_comps <= 0 then
        response:setHeader("Content-Type", "application/json")
        response:appendBody(CJson.encode({ errcode = 0 }))
        return
    end

    -- get site map
    if #path_comps <= 1 and fname == "sitemap" then
        config.logger.info("sitemap")
        self:siteMap(config, req, response, params)
        return
    end

    -- rename path
    if req.query.md and req.query.mf then
        self:movePage(config, req, response, params, path_comps)
        return
    end

    local path = self:fullPath(path_comps)

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
        self:mkdirPathCompos(path_comps)

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

function Page:mkdirPathCompos(path_comps)
    local dir = self.wiki_path
    for i=1, #path_comps - 1 do
        dir = dir .. path_comps[i] .. "/"
        FileManager.mkdir(dir)
    end
end

function Page:siteMap(config, req, response, params)
    local tbl = FileManager.travelDir(self.wiki_path, { file = true, directory = true })
    local out = {}
    self:travelDirTable("", self.wiki_path, tbl, out)
    response:setHeader("Content-Type", "application/json")
    response:appendBody(CJson.encode({
        errcode = 0,
        text = concat(out, '\n'),
    }))
end

function Page:movePage(config, req, response, params, path_comps)
    local npath_comps = self:pathCompos(req.query.md, req.query.mf)
    self:mkdirPathCompos(npath_comps)
    local path = self:fullPath(path_comps)
    local npath = self:fullPath(npath_comps)
    execute("mv -f '" .. path .. "' '" .. npath .. "'")
    config.logger.info("path %s, npath %s", path, npath)
    -- try rmdir empty dir
    path = path:sub(1, path:len() - 3) -- trim '.md'
    for i=#path_comps, 1, -1 do
        config.logger.info("path_comps %s", path_comps[i])
        path = path:sub(1, path:len() - path_comps[i]:len() - 1)
        execute("rmdir " .. path)
    end
    response:setHeader("Content-Type", "application/json")
    response:appendBody(CJson.encode({ errcode = 0 }))
end

function Page:travelDirTable(indent, path, tbl, out)
    for i, v in ipairs(tbl) do
        if v.name:sub(1, 1) == '.' then
        elseif v.attr.mode == "directory" then
            out[#out + 1] = indent .. "- **" .. v.name .. '/**'
            self:travelDirTable(indent .. "  ", path .. v.name .. '/', v, out)
        else
            local dir = path:sub(self.wiki_path:len())
            local htag = "#!" .. dir
            local fname = v.name:sub(1, v.name:len() - 3)
            local suffix = [[ <a style="text-decoration: none;" class="clearfix right mr1" href="javascript:" onclick="wikiMovePage(']] ..  dir .. fname .. [[')">↩</a>]]
            out[#out + 1] = indent .. "- [" .. fname .. '](' .. htag .. fname .. ')' .. suffix
        end
    end
end

function Page:pathCompos(d, f)
    if f then
        local tbl = (d or ""):split("/")
        tbl[#tbl + 1] = f
        for _, v in ipairs(tbl) do
            if v:find("..", 1, true) then
                return {}
            end
        end
        return tbl
    else
        return {}
    end
end

function Page:fullPath(path_comps)
    return self.wiki_path .. concat(path_comps, "/") .. ".md"
end

return Page