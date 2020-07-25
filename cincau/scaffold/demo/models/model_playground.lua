--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local _M = {
    _inputs = {},
    _encodes = {}
}
_M.__index = _M

function _M:pushInput(data)
    self._inputs[#self._inputs + 1] = data
end

function _M:deleteInput(data)
    local index = -1
    for i, v in ipairs(self._inputs) do
        if v == data then
            index = i
            break
        end
    end
    table.remove(self._inputs, index)
end

function _M:allInputs()
    return self._inputs
end

function _M:pushEncodes(v1, v2)
    self._encodes[#self._encodes + 1] = { v1, v2 }
end

function _M:allEncodes()
    return self._encodes
end

return _M
