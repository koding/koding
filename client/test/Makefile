BIN=../node_modules/.bin
SRC=$(shell find lib -name "*.coffee")
TARGETS=$(patsubst %.coffee,build/%.js,$(SRC))
TEST_EXTRAS?=

all: build

build: clean compile configure
	@mkdir -p logs
	@mkdir -p output

compile: $(TARGETS)

configure: globals.js
	@bin/cmd.coffee $(TEST_EXTRAS)

globals.js:
	@coffee -c globals.coffee

build/%.js: %.coffee
	@mkdir -p $(@D)
	@$(BIN)/coffee -p -b $< >$@

clean:
	@rm -fr build

.PHONY: build globals.js
