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

-- register template first
function _M:register(tbl)
    assert(type(tbl) == "table", "invalid register parameter type")
    assert(#tbl > 0, "invalid register table size")
    for _, v in ipairs(tbl) do
        self._templates[tostring(v)] = 1 -- keep non nil
    end
end

-- render interface
function _M:render(name, value_tbl, option)
    assert(type(name) == "string", "invalid view name")
    local tmpl = self._templates[name]
    if type(tmpl) ~= "function" then
        local content = FileManager.readFile("app/views/" .. name .. ".etlua")
        if type(content) == "string" then
            tmpl = CoreEtlua.compile(content)
            assert(type(tmpl) == "function", "failed to compile template")
            if option == nil or option.debug_on then
                self._templates[name] = tmpl
            end
        else
            assert(false, "failed to find template")
        end
    end
    -- return template string
    return tmpl(value_tbl)
end

return _M
