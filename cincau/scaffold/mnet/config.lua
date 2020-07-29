--
-- cincau web framework mnet config

local config = {
    engine_type = "mnet",
    ipport = "127.0.0.1:8080", -- mnet listen ip:port
    logger = require("base.logger"),
    proj_dir = __PROJ_DIR__, -- restrict file_manager operation dir
    debug_on = false, -- debug framework, close cache
}

return config