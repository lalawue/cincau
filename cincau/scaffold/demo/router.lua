--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

-- master controller will cache all using instance controllers
--
local master_ctrl = require("controller_core")

-- list using controller
master_ctrl:register(
    {
        "ctrl_index",
        "ctrl_hello"
    }
)

local r = require("router_core").new()

-- get root
r:get(
    "/",
    function(config, req, response, params)
        master_ctrl:process("ctrl_index", config, req, response, params)
    end
)

r:get(
    "/hello/:name/",
    function(config, req, response, params)
        master_ctrl:process("ctrl_hello", config, req, response, params)
    end
)

return r
