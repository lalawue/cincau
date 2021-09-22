--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

-- master controller will cache all using instance controllers
--
local PageCore = require("page_core")
local MasterPage = PageCore.MasterPage

local router = require("router_core").new()

router:get("/images/:filename/", function(config, req, response, params)
    MasterPage.staticContent(response, "datas/images/" .. params.filename, "image/png")
end)

router:get("/css/:filename/", function(config, req, response, params)
    MasterPage.staticContent(response, "datas/css/" .. params.filename)
end)

-- get root
router:get("/", function(config, req, response, params)
    MasterPage.process("page_index", config, req, response, params)
end)

-- jump to doc and input doc name
router:get("/doc/:name/", function(config, req, response, params)
    MasterPage.process("page_doc", config, req, response, params)
end)

-- get/post in playground page
local function _playground(config, req, response, params)
    MasterPage.process("page_playground", config, req, response, params)
end

router:get("/playground", _playground)
router:post("/playground", _playground)

function router:pageNotFound(config, req, response, params)
    config.logger.err("page not found method:%s path:%s", req.method, req.path)
end

return router
