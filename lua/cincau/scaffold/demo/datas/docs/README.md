
# About

cincau was a minimalist, fast and high configurable web framework for [LuaJIT](http://luajit.org) on [mnet](https://github.com/lalawue/m_net) or [openresty](http://openresty.org/).

## Install

using [LuaRocks](https://luarocks.org/), then create a demo project in `/tmp/demo`, using mnet as network engine

```sh
$ luarocks install cincau
$ cincau
$ Usage: cincau [mnet|nginx] /tmp/demo
$ cincau mnet /tmp/demo
```
## Running

just

```sh
$ cd /tmp/demo
$ ./devop/run_app.sh [ start | stop | reload ]
```

then click this link [http://127.0.0.1:8080](http://127.0.0.1:8080) to get the page, try visit documents link.

## Bundle Binary

with mnet engine, you can bundle all required `.lua`, `.mooc` source and `.so`, too easy to update and shipping, just

```sh
$ ./devop/build_binary.mooc /tmp/build/
...
--
output '/tmp/build/out_20211210_230838.tar.gz' with dir '/tmp/build/build'
```
the bundling process was controled by `./devop/build_binary.mooc`, when you need more rocks in final bundle from [https://luarocks.org/](https://luarocks.org/), edit `./devop/proj-scm-1.rockspec`.

# Demo Project

- app/: contains server entry and business logic
- datas/: contains images, css, js and other documents
- config/: only appears in nginx engine type
- logs/: contains running log
- tmp/: for temporary files

## Config

config files stores in:

- app/config.lua
- config/nginx.conf (only nginx engine)
- config/mime.types (only nginx engine)

you can set app/config.debug_on == true, to disable controllers, views cache.

## Routing

demo use [APItools/router.lua](https://github.com/APItools/router.lua) for routing, you can change it in `app/main.lua`.

when you create a new page, first consider which URL it will use, then add a URL match in router.

## Static Content

the demo project support static content, root directory locates in `datas/www/` dir, when you visit `127.0.0.1:8080/`,
 will return static content `datas/www/index.html`.

 `datas/www/` dir also contains other html, css, javascript files.

## Server-Side Rendering (SSR)

the demo project is quite simple, mostly require [server-side rendering](https://techstacker.com/server-side-rendering-ssr-pros-and-cons/), an old school technology.

### Page Structure (MVC)

demo using MVC (model view controller) pattern , here we call controller as page, and page contains html representation and business logic.

each client request going through these steps below:

- http server parse raw data into http method, path, headers and body content
- router match http path to proper page to process
- page is the center for business logic, using model data and view template to generate html output
- default using template library [lua-resty-template](https://github.com/bungle/lua-resty-template)
- response HTML to client

see `app/pages/page_doc.mooc`, and more complicate example is `app/pages/page_playground.lua`.

## Single Page Application (SPA)

the demo project also provide a SPA page example, with container `app/pages/page_wiki.lua` and data backend `app/pages/page_wikidata.lua`.

you can visit [http://127.0.0.1:8080/wiki](http://127.0.0.1:8080/wiki) to create you own wiki pages, there are some examples in wiki index page.

## Database

default provide SQLite, lua-bitcask and Redis connection support.

### Relational ORM

as a minimalist web framework, the bundle provide [Lua4DaysORM](https://github.com/lalawue/Lua4DaysORM) for SQLite3 ORM.

you can try playground `post text in db`, it will store data in SQLite3.

### NoSQL

the bundle provide Redis with [lua-resp](https://github.com/lalawue/lua-resp) or [lua-bitcask](https://github.com/lalawue/lua-bitcask).

you can try playground `try 'application/x-www-form-urlencoded' text in db`, default using lua-bitcask, you can uncomment _redis_options in model_playground.lua to use redis.

# Technical Details

some technical detail about POST method, query DNS, and raise HTTP Request for mnet engine type, for nginx engine type should use other implementation for these.

## POST something

take look at demo project, run and click playground link.

details about implement POST data, POST `"application/x-www-form-urlencoded"` or POST `"multipart/form-data"`, refers to controller [page_playground.lua](https://github.com/lalawue/cincau/blob/master/lua/cincau/scaffold/demo/app/pages/page_playground.lua).

POST `"multipart/form-data"` example only appears for mnet engine type.

## Query DNS

like POST something, run and click playground link, usage:

```sh
local mediator = require("cincau.bridge.mediator") -- only provided for mnet engine_type
local ipv4 = mediator.queryDomain(domain)
```

only for mnet engine type.

## Raise HTTP Request

recommand using [lua-curl](https://luarocks.org/modules/moteus/lua-curl).

# Thanks

thanks people build useful libraries below, some are MIT License, or with no license from github.

- [golgote/neturl](https://github.com/golgote/neturl), URL and Query string parser, builder, normalizer for Lua
- [APItools/router.lua](https://github.com/APItools/router.lua), A barebones router for Lua. It matches urls and executes lua functions.
- [mpx/lua-cjson](https://github.com/mpx/lua-cjson), Lua CJSON is a fast JSON encoding/parsing module for Lua
- [cyx/cookie.lua](https://github.com/cyx/cookie.lua), basic cookie building / parsing for lua
- [Tieske/date](https://github.com/Tieske/date), Date & Time module for Lua 5.x
- [Tieske/uuid](https://github.com/Tieske/uuid/), A pure Lua uuid generator (modified from a Rackspace module)
- [jsolman/luajit-mime-base64](https://github.com/jsolman/luajit-mime-base64), Fast Mime base64 encoding and decoding implemented in LuaJIT
- [hamishforbes/lua-ffi-zlib](https://github.com/hamishforbes/lua-ffi-zlib)
- [pkulchenko/serpent](https://github.com/pkulchenko/serpent), Lua serializer and pretty printer
- [bungle/lua-resty-template](https://github.com/bungle/lua-resty-template), Templating Engine (HTML) for Lua and OpenResty.
- [ers35/luastatic](https://github.com/ers35/luastatic), Build a standalone executable from a Lua program.
- [lalawue/m_net](https://github.com/lalawue/m_net/), cross platform network library, support LuaJIT's pull style API, using epoll/kqueue/wepoll underlying.
- [lalawue/lua-resp](https://github.com/lalawue/lua-resp), resp from https://github.com/mah0x211/lua-resp
- [lalawue/linked-list](https://github.com/lalawue/linked-list.lua), doubly linked list for Lua
- [lalawue/ffi-hyperparser](https://github.com/lalawue/ffi-hyperparser), LuaJIT HTTP parser with pull-style api
- [lalawue/mooncake](https://github.com/lalawue/mooncake), A Swift like program language compiles into Lua
- [lalawue/Lua4DaysORM](https://github.com/lalawue/Lua4DaysORM), Lua 4Days ORM for sqlite3

EOF
