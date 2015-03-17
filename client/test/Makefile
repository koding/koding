BIN=../node_modules/.bin
SRC=$(shell find lib -name "*.coffee")
TARGETS=$(patsubst %.coffee,build/%.js,$(SRC))
TEST_NW_EXTRAS?=
TEST_EXTRAS?=

all: build run

build: clean $(TARGETS) configure

configure:
	@bin/cmd.coffee browser $(TEST_EXTRAS)

run:
	@$(BIN)/nightwatch \
		--config ../.nightwatch.json \
		--group build \
		$(TEST_NW_EXTRAS)

build/%.js: %.coffee
	@mkdir -p $(@D)
	@$(BIN)/coffee -p -b $< >$@

clean:
	@rm -fr build

.PHONY: build
