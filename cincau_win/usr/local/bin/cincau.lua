
--
-- detect env
--

local engine_type, proj_dir = ...

if not jit then
    print("Only support LuaJIT !")
    os.exit(0)
end

if engine_type ~= "mnet" then
    print("Usage: cincau mnet ./projs/demo")
    os.exit(0)
end

--
-- create cincau project skeleton
--

local core_dir = nil

for path in package.path:gmatch("[^;]+") do
    local len = path:len()
    path = path:sub(1, len - 5)
    local f = io.open(path .. "cincau/page_core.mooc", "r")
    if f then
        f:close()
        core_dir = path .. "cincau/"
        package.path = package.path .. ";" .. core_dir .. "?.lua"
        break
    end
    print(path)
end

if core_dir then
    print("version: " .. require("cincau.base.version").version)
    require("moocscript.core")
    local Proj = require("cincau_prepare")
    Proj.createProjectSkeleton(core_dir, proj_dir, engine_type)
else
    print("Can not found cincau, exit !")
    os.exit(0)
end
