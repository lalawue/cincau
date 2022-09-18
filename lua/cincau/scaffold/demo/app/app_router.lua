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
local MimeLib = require("cincau.base.mime_types")

local Router = require("cincau.router_core").new()

local function staticGet(config, req, response, path, content_type)
    config.logger.info("static GET %s", path)
    local ret = MasterPage.staticContent(config, req, response, path, content_type)
    config.logger.flush()
    return ret
end

local function pageProcess(page_name, config, req, response, params)
    config.logger.info("%s %s %s", req.method, req.path, req.query or '')
    MasterPage.process(page_name, config, req, response, params)
    config.logger.flush()
end

-- get root
Router:get("/", function(config, req, response, params)
    pageProcess("page_index", config, req, response, params)
end)

-- jump to doc and input doc name
Router:get("/doc/:name/", function(config, req, response, params)
    pageProcess("page_doc", config, req, response, params)
end)

-- get/post in playground page
local function _playground(config, req, response, params)
    pageProcess("page_playground", config, req, response, params)
end

Router:get("/playground", _playground)
Router:post("/playground", _playground)

-- wiki get/post
Router:get("/wiki", function(config, req, response, params)
    pageProcess("wiki.page_wiki", config, req, response, params)
end)

local function _wikidata(config, req, response, params)
    pageProcess("wiki.page_wikidata", config, req, response, params)
end
Router:get("/wikidata", _wikidata)
Router:post("/wikidata", _wikidata)

-- page not found
function Router:pageNotFound(config, req, response, params)
    local fsuffix, mime = MimeLib.getPathMIME(req.path)
    if fsuffix and staticGet(config, req, response, "datas/www" .. req.path, mime) then
        -- successful get static content from 'datas/www/'
    else
        response:setStatus(404)
        response:setHeader("Content-Type", "text/html")
        response:appendBody([[<html><head><meta http-equiv="Refresh" content="0; URL=/"></head></html>]])
        config.logger.info("Not found %s %s %s", req.method, req.path, req.query or '')
    end
end

-- first loader
function  Router:loadModel(config)
    -- you can load model before router working
end

return Router
