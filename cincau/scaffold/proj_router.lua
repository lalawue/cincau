--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local r = require("router_core").new()

-- get root
r:get(
    "/",
    function(config, req, response, params)
        print("match root", config, req, response)
        response:setHeader("Content-Type", "text/plain") -- set header before appendBody
        response:appendBody("hello cincau ~")
    end
)

r:get(
    "/hello/:name/",
    function(config, req, response, params)
        print("match hello ", params.name)
        response:setHeader("Content-Type", "text/plain")
        response:appendBody("hello cincau world ~")
    end
)

return r
