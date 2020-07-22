--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

-- view core render template using proper rendering engine
--

local FileManager = require("base.file_manager")
local CoreEtlua = require("render.etlua")

local _M = {
    _config = nil, -- global config
    _templates = {} -- compiled templates
}
_M.__index = {}

-- register file name first
function _M:register(tbl)
    assert(type(tbl) == "table", "invalid register parameter type")
    assert(#tbl > 0, "invalid register table size")
    for _, v in ipairs(tbl) do
        self._templates[tostring(v)] = 1 -- keep non nil
    end
end

local function _noDebug(config)
    return (config == nil) or (not config.debug_on)
end

-- render file
function _M:render(name, value_tbl, config)
    assert(type(name) == "string", "invalid view name")
    local tmpl = self._templates[name]
    if type(tmpl) ~= "function" then
        local content = FileManager.readFile("app/views/" .. name .. ".etlua")
        if type(content) == "string" then
            tmpl = CoreEtlua.compile(content)
            if type(tmpl) ~= "function" then
                config.logger.err("failed to compile: %s", name)
                return nil
            end
            if _noDebug(config) then
                self._templates[name] = tmpl
            end
        else
            config.logger.err("failed to find template: %s", name)
            return nil
        end
    end
    -- return template string
    return tmpl(value_tbl)
end

-- render string with cache_name
function _M:renderString(content, value_tbl, config, cache_name)
    assert(type(content) == "string", "not string")
    assert(type(value_tbl) == "table", "not table")
    local tmpl = nil
    if type(cache_name) == "string" then
        tmpl = self._templates[cache_name]
    end
    if type(tmpl) ~= "function" then
        tmpl = CoreEtlua.compile(content)
        if type(tmpl) ~= "function" then
            config.logger.err("failed to compile: %s", cache_name)
            return nil
        end
        if cache_name and _noDebug(config) then
            self._templates[cache_name] = tmpl
        end
    end
    return tmpl(value_tbl)
end

return _M
