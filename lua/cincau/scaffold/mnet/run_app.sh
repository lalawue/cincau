#!/bin/sh
#
# app launcher by lalawue

start_server()
{
    mkdir -p $PWD/tmp
    mkdir -p $PWD/logs

    local PID_FILE=$PWD/tmp/cincau-mnet.pid
    if [ -f $PID_FILE ]; then
        echo "app already running with pid $(cat $PID_FILE)"
        exit 0
    fi

    # running app
    if [ -f 'bin/app_main' ]; then
        echo "start cincau bianry web framework [mnet]"
        export LUA_PATH=""
        export LUA_CPATH="lib/?.so"
        export LD_LIBRARY_PATH=$PWD/lib
        export DYLD_LIBRARY_PATH=$PWD/lib
        ./bin/app_main $* & >> ./logs/cincau.log
    else
        echo "start cincau web framework [mnet]"
        eval $(luarocks path)
        luajit $PWD/app/app_main.lua $* & >> ./logs/cincau.log
    fi
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
    if [ -f $PID_FILE ]; then
        echo "stop cincau web framework [mnet]"
        kill $(cat $PWD/tmp/cincau-mnet.pid)
    else
        echo "cincau web framework not running [mnet]"
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