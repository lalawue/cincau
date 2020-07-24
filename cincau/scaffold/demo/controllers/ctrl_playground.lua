--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local render = require("view_core")
local model = require("models.model_playground")

local _M = require("controller_core").newInstance()

-- register using template
render:register(
    {
        "view_playground"
    }
)

function _M:process(config, req, response, params)
    -- set header before appendBody
    response:setHeader("Content-Type", "text/html")
    -- if POST, input text
    if req.method == "POST" then
        for k, v in pairs(req.post_args) do
            if k == "input" then
                model:pushInput(v)
            elseif k == "delete" then
                model:deleteInput(v)
            end
        end
    end
    -- render page content
    local page_content =
        render:render(
        "view_playground",
        {
            inputs = model:allInputs()
        },
        config -- for debug purpose
    )
    -- append body as chunked data
    response:appendBody(page_content)
end

return _M
