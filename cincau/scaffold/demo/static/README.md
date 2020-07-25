
# About

cincau was a minimalist, fast and high configurable web framework for [LuaJIT](http://luajit.org) on [mnet](https://github.com/lalawue/m_net) or [openresty](http://openresty.org/cn/) ([nginx](https://www.nginx.com)).

## Install

run command below in sequence:

- make [ mnet | nginx ]
- make install
- cincau.sh /tmp/demo [ mnet | nginx ]

the last command will create a demo project in /tmp/demo.

## Running

in /tmp/demo, just 

```sh
$ ./run_app.sh [ start | stop | reload ]
```

clik this link [http://127.0.0.1:8080](http://127.0.0.1:8080) to get the page, try visit documents link.

## Demo Project

- app/: contains server entry and business logic
- config/: only appears in nginx engine type
- logs/: contains running log
- tmp/: for temporary files

### Config

config files stores in:

- app/config.lua
- config/nginx.conf (only nginx engine)
- config/mime.types (only nginx engine)

you can set app/config.debug_on == true, to disable controllers, views cache.

### MVC

cincau using MVC (model view controller) pattern, each client request going through these steps below:

- http server parse raw data into http method, path, headers and body content
- router match http path to proper controller to process
- controller is the center of business logic, using model data and view template to generate output page
- using template library [etlua](https://github.com/leafo/etlua), using by [Lapis](https://github.com/leafo/lapis)
- response to client

more refers to demo project generate by 

```sh
$ cincau.sh /tmp/demo [mnet|nginx]
```

located in /tmp/demo.

### Database

as a minimalist web framework, default provide sqlite3 connection library [ffi_sqlite3.lua](https://github.com/lalawue/cincau/blob/master/cincau/db/ffi_lsqlite3.lua).

that may be enough for a small web site.

EOF