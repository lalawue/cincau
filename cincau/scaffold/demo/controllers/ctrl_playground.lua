--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local render = require("view_core")
local model = require("models.model_playground")
local Request = require("engine.request_core")

local _M = require("controller_core").newInstance()

function _M:process(config, req, response, params)
    local multipart_info = {}
    -- set header before appendBody
    response:setHeader("Content-Type", "text/html")
    --
    if req.multipart_info then
        for _, info in ipairs(req.multipart_info) do
            multipart_info[#multipart_info + 1] = {
                string.format("name: %s", info.filename),
                string.format("path: %s", info.filepath),
                string.format("content_type: %s", info.content_type)
            }
        end
    elseif req.method == "POST" and not table.isempty(req.post_args) then
        local is_input = false
        -- if body key=value
        for k, v in pairs(req.post_args) do
            if k == "input" then
                is_input = true
                model:pushInput(v)
            elseif k == "delete" then
                is_input = false
                model:deleteInput(v)
            end
        end
        -- if x-www-form-urlencoded as k1=v1&k2=v2
        if not is_input then
            local enc1, enc2 = nil, nil
            for k, v in pairs(req.post_args) do
                if k == "enc1" then
                    enc1 = v
                elseif k == "enc2" then
                    enc2 = v
                end
            end
            if enc1 and enc2 then
                model:pushEncodes(enc1, enc2)
            end
        end
    end
    -- render page content
    local page_content =
        render:render(
        "view_playground",
        {
            inputs = model:allInputs(),
            encodes = model:allEncodes(),
            multipart_info = multipart_info
        },
        config -- for debug purpose
    )
    -- append body as chunked data
    response:appendBody(page_content)
end

return _M
