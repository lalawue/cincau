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

    eval $(luarocks path)

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

