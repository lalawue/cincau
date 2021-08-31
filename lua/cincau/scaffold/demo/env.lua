--
-- Copyright (c) 2021 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local core_dir = nil

for path in package.path:gmatch("[^;]+") do
    local len = path:len()
    path = path:sub(1, len - 5)
    local f = io.open(path .. "cincau/page_core.mooc", "r")
    if f then
        f:close()
        core_dir = path .. "cincau/"
        package.path = package.path .. ";" .. core_dir .. "?.lua;app/?.lua"
        require("moocscript.core")
        return
    end
    print(path)
end
print("Can not found cincau core dir, exit !")
assert(false)
os.exit(0)