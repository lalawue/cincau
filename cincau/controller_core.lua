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
    _inited = false,
    init = function()
    end,
    process = function()
    end
}
_ctrl.__index = _ctrl

function _M.newInstance()
    return setmetatable({}, _ctrl)
end

-- master controller interface
--

local function _debugOn(config)
    return config and config.debug_on
end

local function _debugOff(config)
    return (config == nil) or (not config.debug_on)
end

function _M:process(name, config, ...)
    assert(type(name) == "string", "invalid controller name")
    local ctrl = self._controllers[name]
    if type(ctrl) ~= "table" then
        -- assume all controller business under controllers dir
        ctrl = require("controllers." .. name)
        assert(type(ctrl) == "table", "controller not exist")
        if not ctrl._inited or _debugOn(config) then
            ctrl._inited = true
            ctrl:init(config)
        end
        if _debugOff(config) then
            self._controllers[name] = ctrl
        end
    end
    -- process data
    ctrl:process(config, ...)
end

return _M
