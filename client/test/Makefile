BIN=../node_modules/.bin
SRC=$(shell find lib -name "*.coffee")
TARGETS=$(patsubst %.coffee,build/%.js,$(SRC))
TEST_EXTRAS?=

all: build

build: clean compile configure
	@mkdir -p logs
	@mkdir -p output

compile: $(TARGETS)

configure:
	@bin/cmd.coffee browser $(TEST_EXTRAS)

build/%.js: %.coffee
	@mkdir -p $(@D)
	@$(BIN)/coffee -p -b $< >$@

clean:
	@rm -fr build

.PHONY: build
