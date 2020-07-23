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
        "ctrl_doc",
        "ctrl_playground"
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
    "/doc/:name/",
    function(config, req, response, params)
        master_ctrl:process("ctrl_doc", config, req, response, params)
    end
)

local function _playground(config, req, response, params)
    master_ctrl:process("ctrl_playground", config, req, response, params)
end

r:get("/playground", _playground)
r:post("/playground", _playground)

return r
