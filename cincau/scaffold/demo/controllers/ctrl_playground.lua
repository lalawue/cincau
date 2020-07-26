--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local render = require("view_core")
local model = require("models.model_playground")
local ThreaBroker = require("bridge.thread_broker")
local mDns = require("bridge.ffi_mdns")

local _M = require("controller_core").newInstance()

-- fetch req multipart info to multipart_info table
function _M:_processMultiPartInfo(req, multipart_info)
    for _, info in ipairs(req.multipart_info) do
        multipart_info[#multipart_info + 1] = {
            string.format("name: %s", info.filename),
            string.format("path: %s", info.filepath),
            string.format("content_type: %s", info.content_type)
        }
    end
end

function _M:_processInputDeleteModel(post_args)
    local is_input = false
    -- if body key=value
    for k, v in pairs(post_args) do
        if k == "input" then
            is_input = true
            model:pushInput(v)
        elseif k == "delete" then
            is_input = true
            model:deleteInput(v)
        end
    end
    return is_input
end

-- process x-www-form-urlencoded as k1=v1&k2=v2
function _M:_processUrlEncodedData(post_args)
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
    if enc1 and enc2 then
        model:pushEncodes(enc1, enc2)
    end
    return is_input
end

function _M:_processQueryDomain(post_args, dns_query)
    for k, domain in pairs(post_args) do
        if k == "domain" then
            dns_query[1] = domain
            dns_query[2] =
                ThreaBroker.callThread(
                function(ret_func)
                    mDns.queryHost(
                        domain,
                        function(ipv4)
                            ret_func(ipv4)
                        end
                    )
                end
            )
            return true
        end
    end
    return false
end

-- public interface
--

function _M:process(config, req, response, params)
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
    local page_content =
        render:render(
        "view_playground",
        {
            dns_query = dns_query,
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
