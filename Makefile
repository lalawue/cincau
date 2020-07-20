#
# use gmake in FreeBSD

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S), Darwin)
	SUFFIX=dylib
else
	SUFFIX=so
endif

export MNET_DIR=vendor/m_net
export HP_DIR=vendor/hyperparser
export VD_DIR=cincau/vendor

all:
	@echo "Installation:"
	@echo "\t1. make [mnet|nginx] \t\t\t\t # compile required library"
	@echo "\t2. make install \t\t\t\t # to /usr/local/cincau"
	@echo "\t3. cincau /tmp/demo [mnet|nginx] \t\t # create demo project"

mnet:
	mkdir -p $(VD_DIR)
	if [ ! -d "$(MNET_DIR)" ]; then git clone --depth 1 https://github.com/lalawue/m_net.git $(MNET_DIR) ; fi
	if [ ! -d "$(HP_DIR)" ]; then git clone --depth 1 https://github.com/lalawue/hyperparser $(HP_DIR) ; fi
	make lib -C $(MNET_DIR)
	make -C $(HP_DIR)
	cp -f $(MNET_DIR)/build/libmnet.* $(VD_DIR)/libmnet.$(SUFFIX)
	cp -f $(MNET_DIR)/extension/luajit/ffi_mnet.lua $(VD_DIR)
	cp -f $(HP_DIR)/hyperparser.* $(VD_DIR)/libhyperparser.$(SUFFIX)
	cp -f $(HP_DIR)/ffi_hyperparser.lua $(VD_DIR)

nginx:
	@echo "not implement, to be continue"

install:
	sudo cp -af cincau/ /usr/local/cincau
	sudo cp cincau.sh /usr/local/bin/cincau.sh

clean:
	rm -rf vendor/lib/*
