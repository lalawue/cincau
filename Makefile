#
# use gmake in FreeBSD

.PHONY : test

all:
	@echo "Installation:"
	@echo "\t1. make [mnet|nginx] \t\t\t\t # compile required library"
	@echo "\t2. make install \t\t\t\t # to /usr/local/cincau"
	@echo "\t3. cincau /tmp/demo [mnet|nginx] \t\t # create demo project to /tmp/demo"

mnet:
	sh build_vendor.sh

nginx:
	@echo "not implement, to be continue"

install:
	sudo cp -af cincau/ /usr/local/cincau
	sudo cp cincau.sh /usr/local/bin/cincau.sh

test:
	@export LD_LIBRARY_PATH=cincau/vendor
	@export DYLD_LIBRARY_PATH=cincau/vendor
	lua test/run_test.lua test/cases_multipart.lua

clean:
	rm -rf vendor/lib/*