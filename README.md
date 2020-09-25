
# About

cincau was a minimalist, fast and high configurable web framework for [LuaJIT](http://luajit.org) on [mnet](https://github.com/lalawue/m_net) or [openresty](http://openresty.org/cn/) ([nginx](https://www.nginx.com)).

## Install

first, export like

```sh
$ export LUAJIT_INC_DIR=/usr/local/include
$ export LUAJIT_LIB_DIR=/usr/local/lib
$ export LUAJIT_LIB_NAME=luajit
$ export PKG_CONFIG_PATH=/usr/local/Cellar/openssl@1.1/1.1.1g/lib/pkgconfig
```

then run command below in sequence:

- sh build_vender.sh
- make install
- cincau.sh /tmp/demo [ mnet | nginx ]

the last command will create a demo project in /tmp/demo.

## Running

in /tmp/demo, just 

```sh
$ ./run_app.sh [ start | stop | reload ]
```

then click this link [http://127.0.0.1:8080](http://127.0.0.1:8080) to get the page, try visit documents link.

# Demo Project

- app/: contains server entry and business logic
- config/: only appears in nginx engine type
- logs/: contains running log
- tmp/: for temporary files

## Config

config files stores in:

- app/config.lua
- config/nginx.conf (only nginx engine)
- config/mime.types (only nginx engine)

you can set app/config.debug_on == true, to disable controllers, views cache.

## MVC

cincau using MVC (model view controller) pattern, each client request going through these steps below:

- http server parse raw data into http method, path, headers and body content
- router match http path to proper controller to process
- controller is the center of business logic, using model data and view template to generate output page
- using template library [etlua](https://github.com/leafo/etlua), also used by [Lapis](https://github.com/leafo/lapis)
- response to client

when you write a new page, just add route match url, add new controller for business logic, and a view template for rendering, with model provided data.

more example refers to demo project generate by 

```sh
$ cincau.sh /tmp/demo [mnet|nginx]
```

located in /tmp/demo.

## Database

as a minimalist web framework, default provide sqlite3 connection library [ffi_sqlite3.lua](https://github.com/lalawue/cincau/blob/master/cincau/db/ffi_lsqlite3.lua).

that may be enough for a small web site.

# Technical Details

some technical detail about POST method, query DNS, and raise HTTP Request for mnet engine type, nginx engine type should use other implement for these.

## POST something

take look at demo project, run and click playground link.

details about implement POST data, POST "application/x-www-form-urlencoded" or POST "multipart/form-data", refers to controller [ctrl_playground.lua](https://github.com/lalawue/cincau/blob/master/cincau/scaffold/demo/controllers/ctrl_playground.lua) and view exmaple [view_playground.etlua](https://github.com/lalawue/cincau/blob/master/cincau/scaffold/demo/views/view_playground.etlua).

POST "multipart/form-data" example only appears for mnet engine type.

## Query DNS

like POST something, run and click playground link, usage:

```sh
local mediator = require("bridge.mediator") -- only provided for mnet engine_type
local ipv4 = mediator.queryDomain(domain)
```

only for mnet engine type.

## Raise HTTP Request

```sh
local mediator = require("bridge.mediator") -- only provided for mnet engine_type
local option = {
    reciever = function (header_tbl, data_string)
    end,
}
local header_tbl, data_str = mediator.requestURL("http://www.baidu.com", option)
```

when setting option.reciever function, no data_str return.

only for mnet engine type.

# Thanks

thanks people build useful libraries below, some are MIT License, or with no license from github.

- [golgote/neturl](https://github.com/golgote/neturl), URL and Query string parser, builder, normalizer for Lua
- [APItools/router.lua](https://github.com/APItools/router.lua), A barebones router for Lua. It matches urls and executes lua functions.
- [leafo/etlua](https://github.com/leafo/etlua), Embedded Lua templates
- [mpx/lua-cjson](https://github.com/mpx/lua-cjson), Lua CJSON is a fast JSON encoding/parsing module for Lua
- [cyx/cookie.lua](https://github.com/cyx/cookie.lua), basic cookie building / parsing for lua
- [Tieske/date](https://github.com/Tieske/date), Date & Time module for Lua 5.x
- [Tieske/uuid](https://github.com/Tieske/uuid/), A pure Lua uuid generator (modified from a Rackspace module)
- [jsolman/luajit-mime-base64](https://github.com/jsolman/luajit-mime-base64), Fast Mime base64 encoding and decoding implemented in LuaJIT
- [sonoro1234/luafilesystem](https://github.com/sonoro1234/luafilesystem), Reimplement luafilesystem via LuaJIT FFI with unicode facilities
- [hamishforbes/lua-ffi-zlib](https://github.com/hamishforbes/lua-ffi-zlib)
- [pkulchenko/serpent](https://github.com/pkulchenko/serpent), Lua serializer and pretty printer
- [ColonelThirtyTwo/lsqlite3-ffi](https://github.com/ColonelThirtyTwo/lsqlite3-ffi), Lua SQLite using LuaJIT's FFI library
- [cloudwu/lua-serialize](https://github.com/cloudwu/lua-serialize), Serialize lua objects into a binary block
- [lalawue/m_net](https://github.com/lalawue/m_net/), cross platform network library, support LuaJIT's pull style API, using epoll/kqueue/wepoll underlying.
- [lalawue/hyperparser](https://github.com/lalawue/hyperparser), LuaJIT HTTP parser with pull-style api
- [lalawue/m_foundation](https://github.com/lalawue/m_foundation), platform dependent C librarey
- [lalawue/m_dnscnt](https://github.com/lalawue/m_dnscnt), cross platform standalone or library dns client
- [lalawue/ffi_bitcask.lua](https://github.com/lalawue/ffi_bitcask.lua), Bitcask key/value store for LuaJIT

EOF
