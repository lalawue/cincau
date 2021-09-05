--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local lfs = require("lfs")
local DBClass = require("sql-orm")

local Model = {
    _conn = false,
    _encodes = {}
}
Model.__index = Model

local Table, Field, tpairs, Or
local PostT

function Model:loadModel(config)
    lfs.mkdir(config.db_path)
    if self._conn then
        return
    end
    self._conn = DBClass.new({
        newtable = true,
        path = config.db_path .. "/playground_db.sqlite",
        type = "sqlite3",
        TRACE = true,
        DEBUG = true,
    })
    if not self._conn then
        config.logger.err("fail to open user database, exit 0")
        os.exit(0)
    end
    Table, Field, tpairs, Or = self._conn.Table, self._conn.Field, self._conn.tablePairs, self._conn.OrderBy
    assert(Table)
    assert(Field)
    assert(tpairs)
    assert(Or)
    PostT = Table({
        __tablename__ = "post_t",
        data = Field.CharField({ max_length = 32, unique = true }),
    })
    config.logger.info("open post database")
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
            for i, v in tpairs(datas) do
                    tbl[#tbl + 1] = v.data
            end
            return tbl
    end
    return {}
end

function Model:pushEncodes(v1, v2)
    self._encodes[#self._encodes + 1] = { v1, v2 }
end

function Model:allEncodes()
    return self._encodes
end

return Model
