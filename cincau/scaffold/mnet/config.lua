--
-- cincau web framework mnet config

local config = {
    engine_type = "mnet",
    ipport = "127.0.0.1:8080", -- mnet listen ip:port
    logger = require("base.logger"),
    debug_on = false, -- debug framework, close cache
    poll_wait = 50, -- epoll/kqueue poll microseconds, less cost more CPU
    session_outdate = 300 -- session oudated seconds
}

return config
