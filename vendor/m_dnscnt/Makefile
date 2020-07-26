#
# use gmake in FreeBSD

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S), FreeBSD)
	CC=cc
	MAKE=gmake
else
	CC=gcc
	MAKE=make
endif

ifeq ($(UNAME_S), Darwin)
	LIBNAME=libmdns.dylib
else
	LIBNAME=libmdns.so
endif

CFLAGS= -Wall -O2 -std=gnu99 -Wdeprecated-declarations -shared -fPIC

C_SRCS := $(shell find . -name "*.c")

LIBS := -Lbuild -L../m_net/build -L../m_foundation/build -lmnet -lmfoundation -lpthread

DIRS := $(shell find ../m_net/src -type d)
DIRS += $(shell find ../m_foundation/src -type d)

INCS := $(foreach n, $(DIRS), -I$(n))
INCS +=-I.

NAME := mdns_cnt.out

all:
	mkdir -p build
	$(CC) $(RELEASE) $(CFLAGS) $(INCS) -o build/$(LIBNAME) $(C_SRCS) $(LIBS)


clean:
	rm -rf build