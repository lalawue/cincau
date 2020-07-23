
# About

cincau was a minimallist, fast and high configurable web framework for [LuaJIT](http://luajit.org) on [mnet](https://github.com/lalawue/m_net) or [openresty](http://openresty.org/cn/) ([nginx](https://www.nginx.com)).

## Install

run command below in sequence:

- make [ mnet | nginx ]
- make install
- cincau.sh /tmp/demo [ mnet | nginx ]

the last command will create a demo project in /tmp/demo.

## Running Demo

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

you can set app/config.debug_on == true, to disable config, router (including controller, view, and model) cache.

using code below to reload library when app/config.debug_on == true:

```sh
local router = Lang.import("router")
```

### MVC 

EOF