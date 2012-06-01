ROOT_DIR:=$(shell pwd)
BUILD_ROOT:=$(ROOT_DIR)/build
SRC_ROOT:=$(ROOT_DIR)/src
OBJ_DIR:=$(BUILD_ROOT)/src
SDK_ROOT:=$(ROOT_DIR)/sdk
install-path:=/opt/terminaljs

all: build

install: build install-scripts

install-scripts: coffee
	@echo "installing terminaljs libraries to "$(install-path)
	@mkdir -p $(install-path)
	@cp -fR build/app/nodejs/* $(install-path)

build: SDK dirs libraries

coffee::
	@mkdir -p $(BUILD_ROOT)/app/nodejs/src
	cp -fR ./script/* $(BUILD_ROOT)/app/nodejs/
	coffee -b -c -o $(BUILD_ROOT)/app/nodejs $(BUILD_ROOT)/app/nodejs/src

SDK::
	cd $(SDK_ROOT)&&make;

libraries::
	cd $(SRC_ROOT)&&$(MAKE)

$(BUILD_ROOT) $(BUILD_ROOT)/src $(BUILD_ROOT)/app $(BUILD_ROOT)/sdk :;
	@echo "creating $@ ..."	
	@mkdir -p $@

dirs : $(BUILD_ROOT) $(BUILD_ROOT)/app $(BUILD_ROOT)/sdk 

FORCE:

clean::
	-rm -fr build/app/src
	-rm -fr build/sdk/src
	@echo "done"

clean-all: 
	rm -fr build

pack: build coffee
	cd $(BUILD_ROOT)/app/nodejs&&tar cvzf $(BUILD_ROOT)/anyterm~$(shell cat version)~$(shell uname|tr '[:upper:]' '[:lower:]')~$(shell uname -r | cut -f1-3 -d.)~$(shell uname -m).tar.gz *

