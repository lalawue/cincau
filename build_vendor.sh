#!/bin/sh
#
# vendor library builder

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
HP_DIR=vendor/hyperparser
VD_DIR=cincau/vendor

mkdir -p $VD_DIR
if [ ! -d "$MNET_DIR" ]; then
    git clone --depth 1 https://github.com/lalawue/m_net.git $MNET_DIR
fi
if [ ! -d "$HP_DIR" ]; then
    git clone --depth 1 https://github.com/lalawue/hyperparser $HP_DIR
fi
echo_run "make lib -C $MNET_DIR"
echo_run "make -C $HP_DIR"
echo_run "cp -f $MNET_DIR/build/libmnet.* $VD_DIR/libmnet.$SUFFIX"
echo_run "cp -f $MNET_DIR/extension/luajit/ffi_mnet.lua $VD_DIR"
echo_run "cp -f $HP_DIR/hyperparser.* $VD_DIR/libhyperparser.$SUFFIX"
echo_run "cp -f $HP_DIR/ffi_hyperparser.lua $VD_DIR"
echo "build and copy done"