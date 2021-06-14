#!/bin/sh
#
# app launcher by lalawue

# proj path and core path 
PROJ_PATH=$(dirname $0)

start_server()
{
    mkdir -p $PWD/tmp
    mkdir -p $PWD/logs

    local PID_FILE=$PWD/tmp/cincau-mnet.pid
    if [ -f $PID_FILE ]; then
        echo "app already running with pid $(cat $PID_FILE)"
        exit 0
    fi 

    local CORE_PATH=/usr/local/cincau
    local MN_PATH=/usr/local/opt/moocscript

    # package.path
    local VD_PATH=$CORE_PATH/vendor
    export LUA_PATH="?.lua;$PROJ_PATH/app/?.lua;$CORE_PATH/?.lua;$VD_PATH/?.lua;$MN_PATH/?.lua"

    # package.cpath
    if [ "$(uname)" = "Darwin" ]; then
        export DYLD_LIBRARY_PATH=$VD_PATH
        export LUA_CPATH="$VD_PATH/lib?.dylib;/usr/local/lib/lua/5.1/?.so;"
    else
        export LD_LIBRARY_PATH=$VD_PATH
        export LUA_CPATH="$VD_PATH/lib?.so;/usr/local/lib/lua/5.1/?.so;"
    fi

    # running app
    echo "start cincau web framework [mnet]"    
    luajit $PROJ_PATH/app/main.lua $* & > /dev/null
    CINCAU_PID=$!
    sleep 1
    kill -0 $CINCAU_PID
    if [ $? = "0" ]; then
	echo $CINCAU_PID > $PID_FILE
    else
	echo "fail to start !!!"
    fi
}

stop_server()
{
    PID_FILE=$PWD/tmp/cincau-mnet.pid
    echo "stop cincau web framework [mnet]"
    if [ -f $PID_FILE ]; then
        kill $(cat $PWD/tmp/cincau-mnet.pid)
    fi
    rm -f $PID_FILE
}

reload_server()
{
    stop_server
    sleep 1
    start_server
    exit 0
}

# case command
case $1 in
"start")
    start_server $*
    ;;
"stop")
    stop_server
    ;;
"reload")
    reload_server
    ;;
*)
    echo "$0 [start|stop|reload]"
    ;;
esac

