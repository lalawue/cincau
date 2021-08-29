--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local Model = {
    _inputs = {},
    _encodes = {}
}
Model.__index = Model

function Model:pushInput(data)
    self._inputs[#self._inputs + 1] = data
end

function Model:deleteInput(data)
    local index = -1
    for i, v in ipairs(self._inputs) do
        if v == data then
            index = i
            break
        end
    end
    table.remove(self._inputs, index)
end

function Model:allInputs()
    return self._inputs
end

function Model:pushEncodes(v1, v2)
    self._encodes[#self._encodes + 1] = { v1, v2 }
end

function Model:allEncodes()
    return self._encodes
end

return Model
