--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local FileManager = {}

-- save data to path
function FileManager.saveFile(file_path, data)
    local f = io.open(file_path, "wb")
    if f then
        f:write(data)
        f:close()
        return true
    end
    return false
end

function FileManager.readFile(file_path)
    local f = io.open(file_path, "rb")
    if f then
        local data = f:read("*a")
        f:close()
        return data
    end
    return nil
end

return FileManager
