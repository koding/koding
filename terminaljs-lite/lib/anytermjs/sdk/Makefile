SDK_ROOT:=$(shell pwd)
SDK_SRC_DIR:=$(SDK_ROOT)/src
SDK_BUILD_DIR:=$(SDK_ROOT)/../build/sdk
SDK_LIB_DIR:=$(SDK_BUILD_DIR)/lib
SDK_LIB_STATIC_DIR:=$(SDK_BUILD_DIR)/lib.static
SDK_INCLUDES_DIR:=$(SDK_BUILD_DIR)/include
BOOST:=boost_1_47_0
BOOST_DOWNLOAD_URL:=http://sourceforge.net/projects/boost/files/boost/1.47.0/boost_1_47_0.tar.bz2/download

UNAME_S:=$(shell uname -s)
UNAME_R:=$(shell uname -r)

ifeq (${UNAME_S},Linux)
  KVER=$(subst ., ,${UNAME_R})
  ifeq ($(word 1,${KVER}),2)
    ifeq ($(word 2,${KVER}),4)
      SUPPORT_LINUX_2_4=1
    endif
  endif
endif

CPP_FLAGS+=-I$(LIBPBE_DIR)/include

ifdef SUPPORT_LINUX_2_4
CPP_FLAGS+=-DSUPPORT_LINUX_2_4
endif

LINK_FLAGS+=-L$(LIBPBE_DIR) -lpbe

LIBPBE_LIB:=$(LIBPBE_DIR)/libpbe.a



.PHONY: build

all: build

build : dirs boost libpbe 
	@echo "## SDK installed ."

dirs: $(SDK_BUILD_DIR) $(SDK_LIB_DIR) $(SDK_INCLUDES_DIR) $(SDK_LIB_STATIC_DIR)

	
boost: $(SDK_INCLUDES_DIR)/boost/ $(SDK_LIB_STATIC_DIR)/boost
 
$(SDK_INCLUDES_DIR)/boost/ $(SDK_LIB_STATIC_DIR)/boost :
	mkdir -p $(SDK_BUILD_DIR)/src/boost
	wget -O - $(BOOST_DOWNLOAD_URL)|tar xjf - -C $(SDK_BUILD_DIR)/src/boost
	wget -O $(SDK_BUILD_DIR)/src/boost/boost_log.zip http://sourceforge.net/projects/boost-log/files/latest/download/
	cd $(SDK_BUILD_DIR)/src/boost&&unzip boost_log.zip
	mv $(SDK_BUILD_DIR)/src/boost/boost-log-*/boost/* $(SDK_BUILD_DIR)/src/boost/$(BOOST)/boost/
	mv $(SDK_BUILD_DIR)/src/boost/boost-log-*/libs/*  $(SDK_BUILD_DIR)/src/boost/$(BOOST)/libs/
	cd $(SDK_BUILD_DIR)/src/boost/$(BOOST)&&./bootstrap.sh
	cd $(SDK_BUILD_DIR)/src/boost/$(BOOST)/&&./bjam -d0 --v2 cxxflags=-fPIC --with-iostreams --with-thread --with-system --with-filesystem --with-log define=BOOST_LOG_USE_CHAR --build-type=minimal --layout=tagged --exec-prefix=/ --prefix=/ --includedir=$(SDK_INCLUDES_DIR) --libdir=$(SDK_LIB_STATIC_DIR)/boost variant=release link=static threading=multi install 

libpbe: $(SDK_INCLUDES_DIR)/pbe/ 

$(SDK_INCLUDES_DIR)/pbe/ : $(SDK_SRC_DIR)/pbe
	mkdir -p $(SDK_BUILD_DIR)/src/pbe
	cd $(SDK_SRC_DIR)/pbe&& $(MAKE) BUILD_DIR=$(SDK_BUILD_DIR)/src/pbe SDK_ROOT=$(SDK_BUILD_DIR)
	mkdir -p $(SDK_INCLUDES_DIR)/pbe/
	mkdir -p $(SDK_LIB_STATIC_DIR)/pbe/
	cp -R $(SDK_SRC_DIR)/pbe/include/* $(SDK_INCLUDES_DIR)/pbe/
	cp $(SDK_BUILD_DIR)/src/pbe/libpbe.a $(SDK_LIB_STATIC_DIR)/pbe/

$(SDK_BUILD_DIR) $(SDK_LIB_DIR) $(SDK_INCLUDES_DIR) $(SDK_LIB_STATIC_DIR) : 
	@if [ ! -d "$@" ] ;\
	 then\
	 echo "creating $@ dir ...";\
	 mkdir -p $@;\
	 fi;
clean::
	rm -fr $(SDK_BUILD_DIR)/src
