--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local FileManager = require("base.file_manager")
local _format = string.format

local _M = {
    _paragraphs = {}
}
_M.__index = {}

-- load model
function _M:loadModel()
    local content = FileManager.readFile("app/static/README.md")
    local paragraphs = {}
    for _, v in ipairs(content:split("\n")) do
        if v:len() > 0 then
            paragraphs[#paragraphs + 1] = v
        end
    end
    self._paragraphs = self:md2html(paragraphs)
end

local _md_tbl = {"^##", "^#", "^%-"}
local _h5_tbl = {"h3", "h2", "li"}

-- replace line start with '#' to 'h1', '##' to 'h2', '-' to '<li>', '' to '<p>'
function _M:md2html(paragraphs)
    local last_mtag = ""
    for pi, line in ipairs(paragraphs) do
        local mtag = ""
        -- start with mtag
        for i, v in ipairs(_md_tbl) do
            if line:startwith(v) then
                mtag = v
                line = self:mtag2htag(line, mtag, _h5_tbl[i], last_mtag)
                break
            end
        end
        -- no mtag begin
        if line:len() > 0 and mtag:len() <= 0 then
            line = self:mtag2htag(line, mtag, "p", last_mtag)
        end
        -- store value
        last_mtag = mtag
        paragraphs[pi] = line
    end
    return paragraphs
end

-- add '<ul>' and </ul>
function _M:mtag2htag(line, mtag, htag, last_mtag)
    if mtag:len() > 0 then
        line = line:gsub(mtag, _format("<%s>", htag)) .. _format("</%s>", htag)
    else
        line = _format("<%s>", htag) .. line .. _format("</%s>", htag)
    end
    local li = _md_tbl[#_md_tbl]
    if mtag == li then
        local s, e = line:find("(%s-#)")
        local blank = line:sub(s, e - 1)
        line = line:gsub("(%s-#)", string.rep("&nbsp;", blank:len() * 2.1) .. "#")
    end
    if mtag == li and last_mtag ~= li then
        line = "<ul>" .. line
    elseif mtag ~= li and last_mtag == li then
        line = "</ul>" .. line
    end
    return line
end

function _M:getParagraphs(index)
    return self._paragraphs
end

return _M
