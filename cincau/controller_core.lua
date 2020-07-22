--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

-- controller was a business logic block for data processing
--

local _M = {
    _controllers = {} -- hold all named controller instance
}
_M.__index = _M

-- controller instance
--

local _ctrl = {
    process = function()
    end
}

function _M.newInstance()
    return setmetatable({}, _ctrl)
end

-- master controller interface
--

function _M:register(tbl)
    assert(type(tbl) == "table", "invalid register parameter type")
    assert(#tbl > 0, "invalid register table size")
    for _, v in ipairs(tbl) do
        self._controllers[tostring(v)] = 1 -- keep non nil
    end
end

function _M:process(name, option, ...)
    assert(type(name) == "string", "invalid controller name")
    local ctrl = self._controllers[name]
    assert(ctrl, "please register controller first")
    if type(ctrl) ~= "table" then
        -- assume all controller business under controllers dir
        ctrl = require("controllers." .. name)
        assert(type(ctrl) == "table", "controller not exist")
        assert(type(ctrl.process) == "function", "no process function interface")
        if not option or not option.debug_framework then
            self._controllers[name] = ctrl
        end
    end
    -- process data
    ctrl:process(option, ...)
end

return _M
