PWD:=$(shell pwd)
BUILD_DIR:=$(PWD)/../build
LIB_DIR:=$(PWD)/../lib
OS:=$(shell uname|tr '[:upper:]' '[:lower:]')
MAC:=$(shell uname -m)


all: server

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



