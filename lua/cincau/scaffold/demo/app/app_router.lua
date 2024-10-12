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

-- output static content
local function pageStatic(config, req, response, path, content_type)
    config.logger.info("static GET %s", path)
    local ret = MasterPage.staticContent(config, req, response, path, content_type)
    config.logger.flush()
    return ret
end

-- process dynamic content
local function pageProcess(page_name, config, req, response, params)
    if req.method ~= "WS" then
        config.logger.info("%s %s %s", req.method, req.path, req.query or '')
    end
    MasterPage.process(page_name, config, req, response, params)
    config.logger.flush()
end

-- redirect to path
local function pageRedirect(path, config, req, response)
    response:setHeader("Content-Type", "text/html")
    response:appendBody([[<html><head><meta http-equiv="Refresh" content="0; URL=]].. path .. [["></head></html>]])
    config.logger.info("Redirect to %s", path)
end

-- MARK: static content

-- get root
Router:get("/", function(config, req, response, params)
    pageStatic(config, req, response, "datas/www/index.html", "text/html")
end)

-- MARK: dynamic content

-- jump to doc and input doc name
Router:get("/doc/:name/", function(config, req, response, params)
    if params.name == "cincau" then
        pageProcess("page_doc", config, req, response, params)
    else
        pageRedirect("/404.html", config, req, response)
    end
end)

-- get/post in playground page
local function pagePlayground(config, req, response, params)
    pageProcess("page_playground", config, req, response, params)
end

Router:get("/playground", pagePlayground)
Router:post("/playground", pagePlayground)

-- wiki get/post
Router:get("/wiki", function(config, req, response, params)
    pageProcess("wiki.page_wiki", config, req, response, params)
end)

local function pageWikiData(config, req, response, params)
    pageProcess("wiki.page_wikidata", config, req, response, params)
end
Router:get("/wikidata", pageWikiData)
Router:post("/wikidata", pageWikiData)

-- chat room example

Router:get("/chat", function(config, req, response, params)
    pageProcess("chat.page_chat", config, req, response, params)
end)

Router:ws("/chatdata", function(config, req, response, params)
    pageProcess("chat.page_chatdata", config, req, response, params)
end)

-- when URL not matched, fall to this function
function Router:pageNotFound(config, req, response, params)
    local fsuffix, mime = MimeLib.getPathMIME(req.path)
    if fsuffix and pageStatic(config, req, response, "datas/www" .. req.path, mime) then
        -- successful get static content from 'datas/www/'
    else
        -- redicrect to 404 page
        pageRedirect("/404.html", config, req, response)
        config.logger.info("Not found %s %s %s", req.method, req.path, req.query or '')
    end
end

-- first loader
function  Router:loadModel(config)
    -- you can load model before router working
end

return Router
