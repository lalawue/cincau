--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local render = require("view_core")
local model = require("models.model_doc")

local _M = require("controller_core").newInstance()

-- register using template
render:register(
    {
        "view_doc"
    }
)

-- only run once
function _M:init(config)
    model:loadModel()
end

-- output param.name defined in router.lua
function _M:process(config, req, response, params)
    -- set header before appendBody
    response:setHeader("Content-Type", "text/html")
    -- render page content
    local page_content =
        render:render(
        "view_doc",
        {
            name = self:upperCaseFirstChar(params.name) .. " documents",
            paragraphs = model:getParagraphs()
        },
        config -- for debug purpose
    )
    -- append body as chunked data
    response:appendBody(page_content)
end

function _M:upperCaseFirstChar(str)
    return str:sub(1, 1):upper() .. str:sub(2)
end

return _M
