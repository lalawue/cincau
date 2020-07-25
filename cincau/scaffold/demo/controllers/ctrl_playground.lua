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
    local multipart_info = {}
    -- set header before appendBody
    response:setHeader("Content-Type", "text/html")
    --
    if req.multipart_info then
        multipart_info = {
            string.format("name: %s", req.multipart_info.filename),
            string.format("path: %s", req.multipart_info.filepath),
            string.format("content_type: %s", req.multipart_info.content_type)
        }
    elseif req.method == "POST" and not table.isempty(req.post_args) then
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
            inputs = model:allInputs(),
            multipart_info = multipart_info
        },
        config -- for debug purpose
    )
    -- append body as chunked data
    response:appendBody(page_content)
end

return _M
