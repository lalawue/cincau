--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local UrlCore = require("base.neturl")

local _M = {}
_M.__index = _M

-- path as '/hello/word?q=3&r=4'
local function _parsePath(path)
    local tbl = UrlCore.parse(path)
    return tbl.path, tbl.query
end

function _M.new(method, path, header, body, multipart_info)
    local req = setmetatable({}, _M)
    req.method = method
    req.path, req.query = _parsePath(path)
    req.header = header
    req.body = body or ""
    req.multipart_info = multipart_info
    return req
end

-- '/hello/word?q=3&r=4'
-- path: '/hello/word'
-- query: { q=3, r=4 }
function _M:dumpPath(logger)
    logger.err("--")
    logger.err(self.path)
    for k, v in pairs(self.query) do
        logger.err("%s\t%s", k, v)
    end
    logger.err("---")
end

local function _urlUnescape(str, path)
    local str = str
    if not path then
        str = str:gsub("+", " ")
    end
    return (str:gsub(
        "%%(%x%x)",
        function(c)
            return string.char(tonumber(c, 16))
        end
    ))
end

-- application/x-www-form-urlencoded
--

function _M.isXwwwFormUrlEncoded(header)
    if type(header) ~= "table" then
        return false
    end
    local content_type = header["Content-Type"]
    if type(content_type) ~= "string" then
        return false
    end
    return content_type:find("^application/x%-www%-form%-urlencoded") == 1
end

-- multipart/form-data
--

-- check "multipart/form-data" and init fd_tbl
function _M.isMultiPartFormData(fd_tbl, method, header)
    if fd_tbl._stage ~= nil then
        return true
    end
    if method ~= "POST" then
        return false
    end
    if type(header) ~= "table" then
        return false
    end
    local content_type = header["Content-Type"]
    if type(content_type) ~= "string" then
        return false
    end
    local ret = content_type:find("^multipart/form%-data") == 1
    if ret and not fd_tbl._stage then
        local _, e = content_type:find("boundary=")
        fd_tbl._boundary = content_type:sub(e + 1)
        fd_tbl._data = fd_tbl.data or ""
        --[[
            state:
            0: none info
            1: get begin boundary
            2: get filename, or reach empty slot, advance to next boundary
            3: get content-type
            -> callback with data == nil
            filename < read more data >
            -> callback with data ~= nil
            4: reach next bourndary, or reach end boundary
            -> callback with data ~= nil
        ]]
        fd_tbl._stage = 0
        return true
    end
    return false
end

-- read data and update fd_tbl context, callback(filename, content_type, data) multiple times
function _M.multiPartReadBody(fd_tbl, input_data, callback)
    if input_data:len() <= 0 then
        return false
    end

    local ret_run_next = false
    local fdata = fd_tbl._data .. input_data

    -- check begin boundary
    if fd_tbl._stage == 0 then
        local _, e = fdata:find("--" .. fd_tbl._boundary, 1, true)
        if e then
            -- update stage
            fd_tbl._stage = 1
            fdata = fdata:sub(e + 1)
            --print("1 begin boundary end:", e, "<", fdata:sub(1, 10))
        end
    end

    -- check deposition (filename)
    if fd_tbl._stage == 1 then
        local deposition = fdata:match("\r\nContent%-Disposition: ([^%c]-)\r\n")
        if deposition then
            -- update stage
            fd_tbl._stage = 2
            fdata = fdata:sub(25 + deposition:len() + 1)
            -- get filename
            local filename = deposition:match('filename="([^"]-)"')
            if filename and filename:len() > 0 then
                fd_tbl._filename = _urlUnescape(filename)
                --print("2 deposition:", fd_tbl._filename, "<", fdata:sub(1, 10))
            else
                -- update state, to next boundary
                fd_tbl._stage = 0
                -- no filename, means empty slot, advance to next boundary
                local s, e = fdata:find("\r\n\r\n")
                fdata = fdata:sub((e or 0) + 1)
                --print("2 empty deposition, advance to next boundary", "<", fdata:sub(1, 10))
            end
        end
    end

    -- check content_type
    if fd_tbl._stage == 2 then
        local content_type = fdata:match("Content%-Type: ([^%c]-)\r\n\r\n")
        if content_type then
            -- update stage
            fd_tbl._stage = 3
            fdata = fdata:sub(18 + content_type:len() + 1)
            fd_tbl._content_type = content_type
            -- callback with data == nil
            callback(fd_tbl._filename, fd_tbl._content_type, nil)
            --print("3 content_type:", fd_tbl._content_type, "<", fdata:sub(1, 10))
        end
    end

    -- read file data
    if fd_tbl._stage == 3 then
        local bstr = "--" .. fd_tbl._boundary
        if fdata:len() > bstr:len() + 2 then -- extra '--' in for end boundary
            local s, e = fdata:find(bstr, 1, true)
            if s then
                local data = fdata:sub(1, s - 3) -- trim last '\r\n'
                -- if reach end boundary
                if fdata:sub(e + 1, e + 2) == "--" then
                    -- update state
                    fd_tbl._stage = 4
                    fdata = fdata:sub(2 + e + 1)
                    --print("4 reach end", data:len())
                else
                    -- update state
                    fd_tbl._stage = 0
                    -- reach next file boundary, reset to boundary begin
                    fdata = fdata:sub(s)
                    --print("4 reach next", data:len(), fdata:sub(1, 10))
                    ret_run_next = true
                end
                -- callback with data ~= nil
                callback(fd_tbl._filename, fd_tbl._content_type, data)
            else
                local data = fdata:sub(1, fdata:len() - bstr:len() - 1)
                fdata = fdata:sub(data:len() + 1)
                -- callback with data ~= nil
                callback(fd_tbl._filename, fd_tbl._content_type, data)
                --print("3 data:", data:len())
            end
        end
    end

    -- always update data
    fd_tbl._data = fdata

    -- if reach boundary end, reset it
    if fd_tbl._stage == 4 then
        fd_tbl._stage = nil
    end

    return ret_run_next
end

return _M
