#!/bin/sh
#
# app launcher by lalawue

# proj path and core path 
PROJ_PATH=$(dirname $0)
CORE_PATH=/usr/local/cincau

# package.path
export LUA_PATH="?.lua;$PROJ_PATH/?.lua;$CORE_PATH/?.lua"

# package.cpath
if [ "$(uname)" = "Darwin" ]; then
    export DYLD_LIBRARY_PATH=$CORE_PATH/vendor/lib
    export LUA_CPATH=$CORE_PATH/vendor/lib/lib?.dylib
else
    export LD_LIBRARY_PATH=$CORE_PATH/vendor/lib
    export LUA_CPATH=$CORE_PATH/vendor/lib/lib?.so
fi

# running app
exec luajit $PROJ_PATH/main.lua $*
