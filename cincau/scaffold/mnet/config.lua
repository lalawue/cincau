--
-- cincau web framework mnet config

return {
    engine_type = "mnet",
    ipport = "127.0.0.1:8080", -- mnet listen ip:port
    logger = require("base.logger"),
    debug_on = false, -- debug framework, close cache
}