#!/bin/sh
#
# cincau launcher by lalawue

# check luajit exist
LUA_JIT=luajit

which_program()
{
    which $1 > /dev/null
    if [ "$?" = "1" ]; then
        echo "\'$1\' NOT found, failed to create cincau demo project, exit creation !"
        exit 0
    fi
}

which_program $LUA_JIT

# create demo project
CORE_PATH='/usr/local/cincau'
PROJ_PATH=$1
ENGINE_TYPE=$2

if [ -z "$PROJ_PATH" ]; then
    echo "Usage: $0 /tmp/demo [mnet|nginx] "
    exit 0
fi

if [ -z "$ENGINE_TYPE" ]; then
    ENGINE_TYPE="nginx"
fi

if [ ! -d "$CORE_PATH" ]; then
    ln -sf $PWD/cincau $CORE_PATH
fi

$LUA_JIT $CORE_PATH/proj_prepare.lua $CORE_PATH $PROJ_PATH $ENGINE_TYPE
