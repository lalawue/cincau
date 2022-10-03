@echo off
PATH=%CD%/usr/local/bin;%CD%/usr/local/lib/;%PATH%;
set XCG_CONFIG_HOME=%CD%/usr/local/
set LUA_PATH=./?.lua;%CD%/usr/local/share/lua/5.1/?.lua
set LUA_CPATH=%CD%\usr\local\bin\?.dll;%CD%\usr\local\lib\?.dll;%CD%\usr\local\lib\lua\5.1\?.dll
cmd.exe
