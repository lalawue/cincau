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

function _M.instance()
    local ctrl = setmetatable({}, _M)
    ctrl._controllers = nil -- instance no _controllers
    return ctrl
end

function _M:register(name)
    assert(self.__index == self, "controller instance can not register")
    if type(name) == "string" then
        -- non nil
        self._controllers[name] = 1
    end
    if type(name) == "table" then
        for _, v in ipairs(name) do
            -- non nil
            self._controllers[tostring(v)] = 1
        end
    end
end

function _M:process(name, ...)
    if self.__index ~= self then
        -- instance only process data
        return
    end
    local ctrl = self._controllers[name]
    assert(ctrl, "have not register")
    if type(ctrl) ~= "table" then
        -- assume all controller business under controllers dir
        ctrl = require("controllers." .. name)
        self._controllers[name] = ctrl
    end
    assert(type(ctrl) == "table", "invalid controller")
    assert(type(ctrl.process) == "function", "no process function")
    -- name controller process data
    ctrl:process(...)
end

return _M
