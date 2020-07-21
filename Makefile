#
# use gmake in FreeBSD

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S), Darwin)
	SUFFIX=dylib
else
	SUFFIX=so
endif

all:
	@echo "Installation:"
	@echo "\t1. make [mnet|nginx] \t\t\t\t # compile required library"
	@echo "\t2. make install \t\t\t\t # to /usr/local/cincau"
	@echo "\t3. cincau /tmp/demo [mnet|nginx] \t\t # create demo project"

mnet:
	sh build_vendor.sh

nginx:
	@echo "not implement, to be continue"

install:
	sudo cp -af cincau/ /usr/local/cincau
	sudo cp cincau.sh /usr/local/bin/cincau.sh

clean:
	rm -rf vendor/lib/*
