--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local FileManager = require("cincau.base.file_manager")

local _format = string.format

local Model = {
    _paragraphs = {},
    _md_tbl = {"^# ", "^## ", "^### ", "^```", "^%-"},
    _h5_tbl = {"h2", "h3", "h4", "pre", "li"}
}
Model.__index = Model

    -- load model
function  Model:loadModel()
    local content = FileManager.readFile("datas/docs/README.md")
    local paragraphs = {}
    for _, v in ipairs(content:split("\n")) do
        if v:len() > 0 then
            paragraphs[#paragraphs + 1] = v
        end
    end
    self._paragraphs = self:md2html(paragraphs)
end

    -- replace line start with '#' to 'h1', ...
function Model:md2html(paragraphs)
    local in_mtag = false
    local last_mtag = ""
    for pi, line in ipairs(paragraphs) do
        local mtag = ""
        -- start with mtag
        for i, v in ipairs(self._md_tbl) do
            if line:startwith(v) then
                mtag = v
                line, in_mtag = self:mtag2htag(line, mtag, self._h5_tbl[i], last_mtag, in_mtag)
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
function Model:mtag2htag(line, mtag, htag, last_mtag, in_mtag)
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
function Model:htagReplace(paragraphs)
    local tbl = {}
    local padding = ""
    for _, v in ipairs(paragraphs) do
        if v:startwith("<pre>") then
            padding = v
        elseif v:endwith("</pre>") then
            tbl[#tbl] = tbl[#tbl] .. v
        else
            -- replace mardown's
            -- 1. [name](link) to html link
            -- 2. `content` to html span
            v = v:gsub("%[(.-)%]%((.-)%)", '<a href="%2">%1</a>')
            v = v:gsub("`([^`]+)`", "<span>%1</span>")
            tbl[#tbl + 1] = padding .. v
            padding = ""
        end
    end
    return tbl
end

function Model:getParagraphs()
    return table.concat(self._paragraphs, '\n')
end

return Model
