--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

require("base.scratch")
local config = require("config/proj_config")
local server = require("server")

-- server:run(...) in protected mode
xpcall(
    server.run,
    function(msg)
        print("\nPANIC : " .. tostring(msg) .. "\n")
        print(debug.traceback())
    end,
    --- args with self, ...
    server,
    config.ipport,
    function(req, response)
        table.dump(req)
        table.dump(response)
    end
)
