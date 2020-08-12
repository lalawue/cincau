#!/bin/sh
#
# app launcher by lalawue

start_server()
{
    which $1 > /dev/null
    if [ "$?" = "0" ]; then
        echo "start cincau web framework [nginx]"
        $1 -p $PWD/ -c config/nginx.conf
        exit $?
    fi
}

stop_server()
{
    which $1 > /dev/null
    if [ "$?" = "0" ]; then
        echo "stop cincau web framework [nginx]"
        $1 -s stop -p $PWD/ -c config/nginx.conf
        exit $?
    fi
}

reload_server()
{
    which $1 > /dev/null
    if [ "$?" = "0" ]; then
        echo "reload cincau web framework [nginx]"
        kill -HUP $(cat $PWD/tmp/cincau-nginx.pid)
        exit $?
    fi
}

# case command
case $1 in
"start")
    start_server openresty
    start_server nginx
    ;;
"stop")
    stop_server openresty
    stop_server nginx
    ;;
"reload")
    reload_server openresty
    reload_server nginx
    ;;
*)
    echo "$0 [start|stop|reload]"
    ;;
esac