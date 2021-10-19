--
-- cincau web framework mnet config

local config = {
    engine_type = "mnet",
    ipport = "127.0.0.1:8080", -- mnet listen ip:port

    logger = require("base.logger"),
    log_level = 3, -- debug, refers to base.logger

    debug_on = false, -- debug framework, close cache
    poll_wait = 50, -- epoll/kqueue poll microseconds, less cost more CPU

    session_outdate = 300, -- session oudated seconds
    resources_max_age = 900, -- resources cache-control max-age

    dir = {
        database = "database/",
        wiki = "wiki/",
    },

    dataPath = function(dir)
        return 'datas/' .. dir
    end,

    tmpPath = function(dir)
        return 'tmp/' .. dir
    end,
}

return config
