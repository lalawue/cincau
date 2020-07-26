--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local _M = {
    _threads = {}
}

-- keep thread context in list
function _M.addThread(key, co)
    if type(co) == "thread" then
        _M._threads[tostring(key)] = co
    end
end

-- remove thread context
function _M.removeThread(key)
    if key then
        _M._threads[tostring(key)] = nil
    end
end

local function _dummy_func(...)
end

-- Usage: turn callback into coroutine sequence
-- func_thread(ret_func)
--     .. do anything ..
--     ret_func(ret_value_1, ret_value_2, ...)
-- end
function _M.callThread(func_thread)
    if type(func_thread) ~= "function" then
        return
    end
    local co = coroutine.running()
    if co then
        local ret_func = function(...)
            coroutine.resume(co, ...)
        end
        func_thread(ret_func)
        return coroutine.yield()
    else
        return func_thread(_dummy_func)
    end
end

return _M
