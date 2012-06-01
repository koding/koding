INSTALL_TARGET:=~
SDK_ROOT:=../../build/sdk
SRC_ROOT:=../
CC:=g++
CC_FLAGS:= -pthread -fPIC -I./ -I$(SDK_ROOT)/include/pbe -I$(SDK_ROOT)/include/ -I../

BUILD_ROOT:=../../build/app/libraries
BUILD_DIR:=$(BUILD_ROOT)/log
HEADER_FILES := $(wildcard *.hpp)
OBJ_DIR:=../../build/app/src/libraries/log
SRC_DIR :=$(shell pwd)
CPP_FILES := $(wildcard *.cpp)
OBJ_FILES := $(patsubst %.cpp,$(OBJ_DIR)/%.o,$(CPP_FILES))

all : build
	
build: $(OBJ_DIR) $(HEADER_FILES) $(OBJ_FILES)
	mkdir -p $(BUILD_DIR)/include
	cp *.hpp $(BUILD_DIR)/include
	mkdir -p $(BUILD_DIR)/lib
	ar ruv $(BUILD_DIR)/lib/liblog.a $(OBJ_FILES)

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

$(OBJ_DIR)/%.o : $(SRC_DIR)/%.cpp Makefile 
	@echo  "compiling $@ : ..."
	$(CC) -g -c $(CC_FLAGS) $< -o $@ 
