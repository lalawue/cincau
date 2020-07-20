--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local Serv = {}

-- run server, http_callback(method, path, header, content)
function Serv:run(ipport, http_callback)
    -- nginx ignore ipport, which defined in config/nginx.conf
end

return Serv
