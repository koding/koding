INSTALL_TARGET:=~
SDK_ROOT:=../../build/sdk
BUILD_DIR:=../../build/app/libraries/terminal
SRC_ROOT:=../
OBJ_DIR:=../../build/app/src/libraries/terminal
CC:=g++
CC_FLAGS:= -pthread -fPIC -I./ -I$(SDK_ROOT)/include/ -I$(SDK_ROOT)/include/pbe -I../

SRC_DIR :=$(shell pwd)
CPP_FILES := $(wildcard *.cpp)
OBJ_FILES := $(patsubst %.cpp,$(OBJ_DIR)/%.o,$(CPP_FILES))
ANYTERM_CPP_FILES := $(wildcard *.cc)
ANYTERM_OBJ_FILES := $(patsubst %.cc,$(OBJ_DIR)/%.b,$(ANYTERM_CPP_FILES))


all : build
	
build: $(OBJ_DIR) $(OBJ_FILES) $(ANYTERM_OBJ_FILES)
	mkdir -p $(BUILD_DIR)/include
	mkdir -p $(BUILD_DIR)/lib
	cp *.hpp $(BUILD_DIR)/include
	cp *.hh $(BUILD_DIR)/include
	ar ruv $(BUILD_DIR)/lib/libterm.a $(OBJ_FILES) $(ANYTERM_OBJ_FILES)

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

$(OBJ_DIR)/%.o : $(SRC_DIR)/%.cpp Makefile 
	@echo  "compiling $@ : ..."
	$(CC) -g -c $(CC_FLAGS) $< -o $@ 

$(OBJ_DIR)/%.b : $(SRC_DIR)/%.cc Makefile 
	@echo  "compiling $@ : ..."
	$(CC) -g -c $(CC_FLAGS) $< -o $@ 


