#!/bin/sh
#
# vendor library builder

print_var()
{
    echo "$1LUAJIT_INC_DIR=$LUAJIT_INC_DIR"
    echo "$1LUAJIT_LIB_DIR=$LUAJIT_LIB_DIR"
    echo "$1LUAJIT_LIB_NAME=$LUAJIT_LIB_NAME"
    echo "$1PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
}

if [ ! "$LUAJIT_INC_DIR" ] || [ ! "$LUAJIT_LIB_DIR" ] || [ ! "$LUAJIT_LIB_NAME" ] || [ ! "$PKG_CONFIG_PATH" ]; then
    echo "First export variable below:"
    print_var "export "
    echo "try install openssl 1.1.1_ from apt-get or brew install"
    exit 0
fi

echo "with building options:"
print_var " "
echo ""
sleep 3

echo_run()
{
    echo $1
    eval $1
}

if [ $(uname -s) = "Darwin" ]; then
    SUFFIX=dylib
else
    SUFFIX=so
fi

MNET_DIR=vendor/m_net
MDNSUTILS_DIR=vendor/m_dnsutils
HP_DIR=vendor/hyperparser
OPENSSL_DIR=vendor/openssl
CJSON_DIR=vendor/cjson
CJSON_FILES="lua_cjson.c strbuf.c fpconv.c"
RESP_FILES="resp.c lauxhlib.c"
RESP_DIR=vendor/lua-resp
PACKER_DIR=vendor/serialize
VD_DIR=cincau/vendor

LUA_FLAGS="-I$LUAJIT_INC_DIR -L$LUAJIT_LIB_DIR -l$LUAJIT_LIB_NAME"

mkdir -p $VD_DIR
if [ ! -d "$MNET_DIR" ]; then
    git clone --depth 1 https://github.com/lalawue/m_net.git $MNET_DIR
fi
if [ ! -d "$MDNSUTILS_DIR" ]; then
    git clone --depth 1 https://github.com/lalawue/m_dnsutils.git $MDNSUTILS_DIR
fi
if [ ! -d "$HP_DIR" ]; then
    git clone --depth 1 https://github.com/lalawue/ffi_hyperparser $HP_DIR
fi
if [ ! -d "$OPENSSL_DIR" ]; then
    git clone --depth 1 --recurse https://github.com/zhaozg/lua-openssl.git $OPENSSL_DIR
fi
if [ ! -d "$RESP_DIR" ]; then
    git clone  --depth 1 https://github.com/lalawue/lua-resp.git $RESP_DIR
fi
if [ ! -d "$PACKER_DIR" ]; then
    git clone  --depth 1 https://github.com/lalawue/lua-serialize.git $PACKER_DIR
fi

# make
echo_run "make lib -C $MNET_DIR"
echo_run "cd $MDNSUTILS_DIR && gcc -std=c99 -o libmdns_utils.$SUFFIX -O3 -shared -fPIC mdns_utils.c && cd -"
echo_run "make -C $HP_DIR"
echo_run "cd $CJSON_DIR && gcc -o libcjson.$SUFFIX -O3 -shared -fPIC $LUA_FLAGS $CJSON_FILES && cd -"
echo_run "make -C $OPENSSL_DIR"
echo_run "cd $RESP_DIR/src && gcc -o ../libresp.$SUFFIX -O3 -shared -fPIC -I./ $LUA_FLAGS $RESP_FILES && cd -"
echo_run "cd $PACKER_DIR && gcc -o libpacker.$SUFFIX -O3 -shared -fPIC $LUA_FLAGS lpacker.c && cd -"
# copy
echo_run "cp -f $MNET_DIR/build/libmnet.* $VD_DIR/libmnet.$SUFFIX"
echo_run "cp -f $MNET_DIR/extension/luajit/ffi_mnet.lua $VD_DIR"
echo_run "cp -f $MDNSUTILS_DIR/libmdns_utils.* $VD_DIR/libmdns_utils.$SUFFIX"
echo_run "cp -f $HP_DIR/hyperparser.* $VD_DIR/libhyperparser.$SUFFIX"
echo_run "cp -f $HP_DIR/ffi_hyperparser.lua $VD_DIR"
echo_run "cp -f $CJSON_DIR/libcjson.$SUFFIX $VD_DIR/libcjson.$SUFFIX"
echo_run "cp -f $OPENSSL_DIR/openssl.so $VD_DIR/libopenssl.$SUFFIX"
echo_run "cp -f $RESP_DIR/libresp.$SUFFIX $VD_DIR/libresp.$SUFFIX"
echo_run "cp -f $PACKER_DIR/libpacker.$SUFFIX $VD_DIR/libpacker.$SUFFIX"
echo "build and copy done"
