PWD:=$(shell pwd)
BUILD_DIR:=$(PWD)/../build
LIB_DIR:=$(PWD)/../lib
OS:=$(shell uname|tr '[:upper:]' '[:lower:]')
MAC:=$(shell uname -m)

ifdef npm_config_module
target :=$(npm_config_module) clean
else
target := server client clean
endif

ifdef npm_config_use
use:=$(npm_config_use)
else
ifndef use
use:=bin
endif
endif

all: $(use)

src::
	mkdir -p $(BUILD_DIR)
	$(MAKE) -C $(LIB_DIR)/anytermjs install install-path=$(BUILD_DIR)/anyterm
	npm --force install $(BUILD_DIR)/anyterm
	rm -fr $(BUILD_DIR)




bin::
	mkdir -p $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/anyterm
	tar xvzf $(LIB_DIR)/packs/anyterm~*~$(OS)~*$(MAC).tar.gz -C $(BUILD_DIR)/anyterm
	npm --force install $(BUILD_DIR)/anyterm
	rm -fr $(BUILD_DIR)


client::
	cd client&&$(MAKE)


