--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

-- master controller will cache all using instance controllers
--
local PageCore = require("cincau.page_core")
local MasterPage = PageCore.MasterPage

local router = require("cincau.router_core").new()

local function staticGet(config, req, response, path, content_type)
    config.logger.info("static GET %s", path)
    MasterPage.staticContent(config, req, response, path, content_type)
    config.logger.flush()
end

router:get("/images/:filename/", function(config, req, response, params)
    staticGet(config, req, response, "datas/images/" .. params.filename, "image/png")
end)

router:get("/css/:filename/", function(config, req, response, params)
    staticGet(config, req, response, "datas/css/" .. params.filename)
end)

router:get("/js/:filename/", function(config, req, response, params)
    staticGet(config, req, response, "datas/js/" .. params.filename, "application/javascript")
end)

local function pageProcess(page_name, config, req, response, params)
    config.logger.info("%s %s %s", req.method, req.path, req.query or '')
    MasterPage.process(page_name, config, req, response, params)
    config.logger.flush()
end

-- get root
router:get("/", function(config, req, response, params)
    pageProcess("page_index", config, req, response, params)
end)

-- jump to doc and input doc name
router:get("/doc/:name/", function(config, req, response, params)
    pageProcess("page_doc", config, req, response, params)
end)

-- get/post in playground page
local function _playground(config, req, response, params)
    pageProcess("page_playground", config, req, response, params)
end

router:get("/playground", _playground)
router:post("/playground", _playground)

-- wiki get/post
router:get("/wiki", function(config, req, response, params)
    pageProcess("wiki.page_wiki", config, req, response, params)
end)

local function _wikidata(config, req, response, params)
    pageProcess("wiki.page_wikidata", config, req, response, params)
end
router:get("/wikidata", _wikidata)
router:post("/wikidata", _wikidata)

-- page not found
function router:pageNotFound(config, req, response, params)
    if req.path == "/favicon.ico" then
        staticGet(config, req, response, "datas/images/favicon.png", "image/png")
    else
        response:setStatus(404)
        response:setHeader("Content-Type", "text/html")
        response:appendBody([[<html><head><meta http-equiv="Refresh" content="0; URL=/"></head></html>]])
        config.logger.info("Not found %s %s %s", req.method, req.path, req.query or '')
    end
end

-- first loader
function  router:loadModel(config)
    -- you can load model before router working
end

return router
