--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local DBClass = require("sql-orm")
local Bitcask = require("bitcask")
local Redis = require("cincau.bridge.redis_cmd")
local FileManager = require("cincau.base.file_manager")

local type = type
local ipairs = ipairs
local assert = assert

local Model = {
    _db_ins = false,
    _bitcask = false,

    -- uncomment to use redis
    --_redis_options = { ipv4 = '127.0.0.1', port = 6379, keep_alive = false },
}
Model.__index = Model

local Table, Field, Order
local PostT

function Model:loadModel(config)
    self.db_path = config.dataPath(config.dir.database)
    FileManager.mkdir(self.db_path)

    if self._ins then
        return
    end

    self._db_ins, Table, Field, Order = DBClass({
        new_table = true,
        db_path = self.db_path .. "playground_db.sqlite",
        db_type = "sqlite3",
        log_trace = true,
        log_debug = true,
    })

    if not self._db_ins then
        config.logger.err("fail to open user database, exit 0")
        os.exit(0)
    end
    assert(Table)
    assert(Field)
    assert(Order)
    PostT = Table({
        table_name = "post_t",
    }, {
        data = Field.CharField({ max_length = 32, unique = true }),
    })
    config.logger.info("open post database")

    if not self._redis_options then
        self._bitcask = Bitcask.opendb({
            dir = self.db_path .. "bitcask",
            file_size = 1024
        })
    end
end

function Model:pushInput(data)
    if type(data) == "string" and data:len() > 0 then
        local post_data = PostT({
            data = data
        })
        post_data:save()
    end
end

function Model:deleteInput(data)
    if type(data) == "string" and data:len() > 0 then
        PostT.get:where({ data = data }):delete()
    end
end

function Model:allInputs()
    local datas = PostT.get:all()
    if datas then
            local tbl = {}
            for i, v in ipairs(datas) do
                    tbl[#tbl + 1] = v.data
            end
            return tbl
    end
    return {}
end

function Model:pushEncodes(v1, v2)
    if self._bitcask then
        self._bitcask:set(v1, v2)
    else
        if v1 and v2 then
            Redis.runCMD(self._redis_options, { "SET", v1, v2 })
        end
    end
end

function Model:allEncodes()
    local tbl = {}
    if self._bitcask then
        local keys = self._bitcask:allKeys()
        for i, k in ipairs(keys) do
            tbl[i] = { k, self._bitcask:get(k) or ""}
        end
    else
        local keys = Redis.runCMD(self._redis_options, { "KEYS", "*" })
        for i, k in ipairs(keys) do
            tbl[i] = { k, Redis.runCMD(self._redis_options, { "GET", k }) or ""}
        end
    end
    return tbl
end

return Model
