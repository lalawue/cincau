#!/bin/sh
#
# vendor library builder

if [ ! "$1" ] || [ ! "$2" ] || [ ! "$3" ]; then
    echo "$0 LUAJIT_INC_DIR LUAJIT_LIB_DIR LUAJIT_LIB_NAME"
    exit 0
fi

LUAJIT_INC_DIR=$1
LUAJIT_LIB_DIR=$2
LUAJIT_LIB_NAME=$3

echo "LUAJIT_INC_DIR: $LUAJIT_INC_DIR"
echo "LUAJIT_LIB_DIR: $LUAJIT_LIB_DIR"
echo "LUAJIT_LIB_NAME: $LUAJIT_LIB_NAME"
sleep 3

echo_run()
{
    echo $1
    eval $1
}

if [ $(uname -s) == "Darwin" ]; then
    SUFFIX=dylib
else
    SUFFIX=so
fi

MNET_DIR=vendor/m_net
MFOUNDATION_DIR=vendor/m_foundation
MDNSCNT_DIR=vendor/m_dnscnt
HP_DIR=vendor/hyperparser
CURL_DIR=vendor/curl
CURL_FILES="src/l52util.c src/lceasy.c src/lcerror.c src/lchttppost.c src/lcmime.c src/lcmulti.c src/lcshare.c src/lcurl.c src/lcurlapi.c src/lcutils.c"
CJSON_DIR=vendor/cjson
CJSON_FILES="lua_cjson.c strbuf.c fpconv.c"
VD_DIR=cincau/vendor

mkdir -p $VD_DIR
if [ ! -d "$MNET_DIR" ]; then
    git clone --depth 1 https://github.com/lalawue/m_net.git $MNET_DIR
fi
if [ ! -d "$MFOUNDATION_DIR" ]; then
    git clone --depth 1 https://github.com/lalawue/m_foundation.git $MFOUNDATION_DIR
fi
if [ ! -d "$HP_DIR" ]; then
    git clone --depth 1 https://github.com/lalawue/hyperparser $HP_DIR
fi
if [ ! -d "$CURL_DIR" ]; then
    git clone --depth 1 https://github.com/Lua-cURL/Lua-cURLv3.git $CURL_DIR
fi
if [ ! -d "$CJSON_DIR" ]; then
   git clone --depth 1 https://github.com/openresty/lua-cjson.git $CJSON_DIR
fi
# make
echo_run "make lib -C $MNET_DIR"
echo_run "make release -C $MFOUNDATION_DIR"
echo_run "make -C $MDNSCNT_DIR"
echo_run "make -C $HP_DIR"
echo_run "cd $CURL_DIR && gcc -o liblcurl.$SUFFIX -O3 -shared -fPIC -I$LUAJIT_INC_DIR -L$LUAJIT_LIB_DIR -l$LUAJIT_LIB_NAME -lcurl $CURL_FILES && cd -"
echo_run "cd $CJSON_DIR && gcc -o libcjson.$SUFFIX -O3 -shared -fPIC -I$LUAJIT_INC_DIR -L$LUAJIT_LIB_DIR -l$LUAJIT_LIB_NAME $CJSON_FILES && cd -"
# copy
echo_run "cp -f $MNET_DIR/build/libmnet.* $VD_DIR/libmnet.$SUFFIX"
echo_run "cp -f $MNET_DIR/extension/luajit/ffi_mnet.lua $VD_DIR"
echo_run "cp -f $MFOUNDATION_DIR/build/libmfoundation.* $VD_DIR/libmfoundation.$SUFFIX"
echo_run "cp -f $MDNSCNT_DIR/build/libmdns.* $VD_DIR/libmdns.$SUFFIX"
echo_run "cp -f $HP_DIR/hyperparser.* $VD_DIR/libhyperparser.$SUFFIX"
echo_run "cp -f $HP_DIR/ffi_hyperparser.lua $VD_DIR"
echo_run "cp -f $CURL_DIR/liblcurl.$SUFFIX $VD_DIR/liblcurl.$SUFFIX"
echo_run "cp -f $CJSON_DIR/libcjson.$SUFFIX $VD_DIR/libcjson.$SUFFIX"
echo "build and copy done"
