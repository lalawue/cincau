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

if [ $(uname -s) == "Darwin" ]; then
    SUFFIX=dylib
else
    SUFFIX=so
fi

MNET_DIR=vendor/m_net
MFOUNDATION_DIR=vendor/m_foundation
MDNSCNT_DIR=vendor/m_dnscnt
HP_DIR=vendor/hyperparser
OPENSSL_DIR=vendor/openssl
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
if [ ! -d "$OPENSSL_DIR" ]; then
    git clone --depth 1 --recurse https://github.com/zhaozg/lua-openssl.git $OPENSSL_DIR
fi
# make
echo_run "make lib -C $MNET_DIR"
echo_run "make release -C $MFOUNDATION_DIR"
echo_run "make -C $MDNSCNT_DIR"
echo_run "make -C $HP_DIR"
echo_run "cd $CJSON_DIR && gcc -o libcjson.$SUFFIX -O3 -shared -fPIC -I$LUAJIT_INC_DIR -L$LUAJIT_LIB_DIR -l$LUAJIT_LIB_NAME $CJSON_FILES && cd -"
echo_run "make -C $OPENSSL_DIR"
# copy
echo_run "cp -f $MNET_DIR/build/libmnet.* $VD_DIR/libmnet.$SUFFIX"
echo_run "cp -f $MNET_DIR/extension/luajit/ffi_mnet.lua $VD_DIR"
echo_run "cp -f $MFOUNDATION_DIR/build/libmfoundation.* $VD_DIR/libmfoundation.$SUFFIX"
echo_run "cp -f $MDNSCNT_DIR/build/libmdns.* $VD_DIR/libmdns.$SUFFIX"
echo_run "cp -f $HP_DIR/hyperparser.* $VD_DIR/libhyperparser.$SUFFIX"
echo_run "cp -f $HP_DIR/ffi_hyperparser.lua $VD_DIR"
echo_run "cp -f $CJSON_DIR/libcjson.$SUFFIX $VD_DIR/libcjson.$SUFFIX"
echo_run "cp -f $OPENSSL_DIR/openssl.so $VD_DIR/libopenssl.$SUFFIX"
echo "build and copy done"
