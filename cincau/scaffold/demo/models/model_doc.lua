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

local _md_tbl = {"^# ", "^## ", "^### ", "^```", "^%-"}
local _h5_tbl = {"h2", "h3", "h4", "pre", "li"}

-- replace line start with '#' to 'h1', ...
function _M:md2html(paragraphs)
    local in_mtag = false
    local last_mtag = ""
    for pi, line in ipairs(paragraphs) do
        local mtag = ""
        -- start with mtag
        for i, v in ipairs(_md_tbl) do
            if line:startwith(v) then
                mtag = v
                line, in_mtag = self:mtag2htag(line, mtag, _h5_tbl[i], last_mtag, in_mtag)
                last_mtag = mtag
                break
            end
        end
        -- no mtag begin
        if line:len() > 0 and mtag:len() <= 0 then
            line, in_mtag = self:mtag2htag(line, mtag, "p", last_mtag, in_mtag)
        end
        -- store value
        paragraphs[pi] = line
    end
    -- replace link and tidy pre tag
    return self:htagReplace(paragraphs)
end

-- add '<ul>' and </ul>
function _M:mtag2htag(line, mtag, htag, last_mtag, in_mtag)
    local mpre = "^```"
    if mtag == mpre then
        -- ``` and pre
        in_mtag = not in_mtag
        local pattern = in_mtag and (mpre .. "%a+") or mpre
        line = line:gsub(pattern, in_mtag and "<pre><code>" or "</code></pre>")
    elseif not in_mtag then
        -- h and li transform
        if mtag:len() > 0 then
            line = line:gsub(mtag, _format("<%s>", htag)) .. _format("</%s>", htag)
        else
            line = _format("<%s>", htag) .. line .. _format("</%s>", htag)
        end
        -- detect first and last li
        local mli = "^%-"
        if mtag == mli and last_mtag ~= mli then
            line = "<ul>" .. line
        elseif mtag ~= mli and last_mtag == mli then
            line = "</ul>" .. line
        end
    end
    return line, in_mtag
end

-- nested code between <pre> and </pre>, and links
function _M:htagReplace(paragraphs)
    local tbl = {}
    local padding = ""
    for _, v in ipairs(paragraphs) do
        if v:startwith("<pre>") then
            padding = v
        elseif v:endwith("</pre>") then
            tbl[#tbl] = tbl[#tbl] .. v
        else
            -- replace mardown's [name](link) to htmls
            v = v:gsub("%[(.-)%]%((.-)%)", '<a href="%2">%1</a>')
            tbl[#tbl + 1] = padding .. v
            padding = ""
        end
    end
    return tbl
end

function _M:getParagraphs()
    return self._paragraphs
end

return _M
