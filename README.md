
- [About](#about)
  - [Install](#install)
  - [Running](#running)
  - [Bundle Binary](#bundle-binary)
- [Demo Project](#demo-project)
  - [Config](#config)
  - [Routing](#routing)
  - [Static Content](#static-content)
  - [Server-Side Rendering (SSR)](#server-side-rendering-ssr)
    - [Page Structure (MVC)](#page-structure-mvc)
  - [Single Page Application (SPA)](#single-page-application-spa)
  - [WebSocket](#websocket)
  - [Database](#database)
    - [Relational ORM](#relational-orm)
    - [NoSQL](#nosql)
  - [Multiprocess](#multiprocess)
- [Technical Details](#technical-details)
  - [POST something](#post-something)
  - [Query DNS](#query-dns)
  - [Raise HTTP Request](#raise-http-request)
- [Thanks](#thanks)

# About

cincau was a minimalist, fast and high configurable web framework for [LuaJIT](http://luajit.org) on [mnet](https://github.com/lalawue/m_net) or [openresty](http://openresty.org/).

## Install

using [LuaRocks](https://luarocks.org/), and show help

```sh
$ luarocks install cincau
$ cincau
$ Usage: cincau [mnet|nginx] /tmp/demo
```

then create a demo project in `/tmp/demo`, using mnet as network engine

```sh
$ cincau mnet /tmp/demo
version: cincau/0.10.20220924
create cincau demo project with:
core_dir:	/Users/lalawue/rocks/share/lua/5.1/cincau/
proj_dir:	/tmp/demo
engine_type:	mnet
--
mkdir -p /tmp/demo/tmp
mkdir -p /tmp/demo/logs
---
cp -af /Users/lalawue/rocks/share/lua/5.1/cincau//scaffold/demo/* /tmp/demo
cp -af /Users/lalawue/rocks/share/lua/5.1/cincau//scaffold/mnet/app_config.mooc /tmp/demo/app//app_config.mooc
cp -af /Users/lalawue/rocks/share/lua/5.1/cincau//scaffold/mnet/run_app.sh /tmp/demo/devop/run_app.sh
```

## Running

enter demo project dir, just

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
- datas/: contains sqlite database, or lua-bitcask data files
- datas/www/: contains static content like html, css, js and images
- config/: only appears in nginx engine type
- logs/: contains running log
- tmp/: for temporary files

## Config

config files stores in:

- app/app_config.mooc
- config/nginx.conf (only nginx engine)
- config/mime.types (only nginx engine)

you can modify `app/app_config.mooc`, set debug_on = true, to disable controllers, views cache.

## Routing

demo use [APItools/router.lua](https://github.com/APItools/router.lua) for routing, you can add your own route in `app/app_router.lua`.

when you create a new page, first consider which URL it will use, then add a URL match in router.

for example:

```lua
Router:get("/doc/:name/", function(config, req, response, params)
   config.logger.info("params.name: '%s'", params.name)
   pageRedirect("/404.html", config, req, response)
end)
```

then visit with `curl`

```sh
$ curl http://127.0.0.1:8080/doc/hello
```

and logger will output

```sh
[info] 2022-10-30 00:11:23 app_router.lua params.name: 'hello'
[info] 2022-10-30 00:11:23 app_router.lua Redirect to /404.html
```

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

the demo project also provide a SPA page example, with container `app/pages/wiki/page_wiki.lua` and data backend `app/pages/wiki/page_wikidata.lua`.

you can visit [http://127.0.0.1:8080/wiki](http://127.0.0.1:8080/wiki) to create you own wiki pages, there are some examples in wiki index page.

## WebSocket

the demo project also provide a chat room exmaple, with container `app/pages/chat/page_chat.mooc` and data backend `app/pages/chat/page_chatdata.mooc`.

you can visit [http://127.0.0.1:8080/chat](http://127.0.0.1:8080/chat) to play in chat room.

## Database

default provide SQLite, lua-bitcask and Redis connection support.

### Relational ORM

as a minimalist web framework, the bundle provide [Lua4DaysORM](https://github.com/lalawue/Lua4DaysORM) for SQLite3 ORM.

you can try playground `post text in db`, it will store data in SQLite3.

### NoSQL

the bundle provide Redis with [lua-resp](https://github.com/lalawue/lua-resp) or [lua-bitcask](https://github.com/lalawue/lua-bitcask).

you can try playground `try 'application/x-www-form-urlencoded' text in db`, default using lua-bitcask, you can uncomment _redis_options in model_playground.lua to use redis.

## Multiprocess

the demo project support multiprocess under MacOS/Linux, in `app/app_config.mooc`'s config.multiprocess section, you can remove this section for running in single process.

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
- [lalawue/ffi-http1-session](https://github.com/lalawue/ffi-http1-session), LuaJIT HTTP/WebSocket parser with pull-style api
- [lalawue/mooncake](https://github.com/lalawue/mooncake), A Swift like program language compiles into Lua
- [lalawue/Lua4DaysORM](https://github.com/lalawue/Lua4DaysORM), Lua 4Days ORM for sqlite3

EOF
