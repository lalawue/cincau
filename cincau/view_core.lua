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

local function _debugOff(config)
    return (config == nil) or (not config.debug_on)
end

-- render file
function _M:render(name, value_tbl, config)
    assert(type(name) == "string", "invalid view name")
    local tmpl = self._templates[name]
    --  template not loaded
    if type(tmpl) ~= "function" then
        local content = FileManager.readFile("app/views/" .. name .. ".etlua")
        -- invalid template
        if type(content) ~= "string" then
            config.logger.err("failed to find view: %s", name)
            return nil
        else
            tmpl = CoreEtlua.compile(content)
            if type(tmpl) ~= "function" then
                config.logger.err("failed to compile view: %s", name)
                return nil
            end
            if _debugOff(config) then
                self._templates[name] = tmpl
            end
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
    -- read cache_name first
    if type(cache_name) == "string" then
        tmpl = self._templates[cache_name]
    end
    if type(tmpl) ~= "function" then
        tmpl = CoreEtlua.compile(content)
        if type(tmpl) ~= "function" then
            config.logger.err("failed to compile string: %s", cache_name)
            return nil
        end
        if cache_name and _debugOff(config) then
            self._templates[cache_name] = tmpl
        end
    end
    return tmpl(value_tbl)
end

return _M
