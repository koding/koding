BIN=../node_modules/.bin
SRC=$(shell find lib -name "*.coffee")
TARGETS=$(patsubst %.coffee,build/%.js,$(SRC))
TEST_EXTRAS?=

all: build run

build: clean compile configure
	@mkdir -p logs
	@mkdir -p output

compile: $(TARGETS)

configure:
	@bin/cmd.coffee browser $(TEST_EXTRAS)

run:
	@./run.sh register
	@./run.sh login
	@./run.sh logout
	@./run.sh activity post
	@./run.sh activity postwith
	@./run.sh activity editdelete
	@./run.sh activity likeunlike
	@./run.sh activity others
	@./run.sh messages privatemessage
	@./run.sh account accountpage
	@./run.sh account accountsettings
	@./run.sh pricing payment
	@./run.sh ide file
	@./run.sh ide terminal
	@./run.sh ide layout
	@./run.sh ide workspace
	@./run.sh ide general
	@./run.sh staticpages loggedout
	@./run.sh environments vm
	@./run.sh environments domain
	@./run.sh environments paidaccount

build/%.js: %.coffee
	@mkdir -p $(@D)
	@$(BIN)/coffee -p -b $< >$@

clean:
	@rm -fr build

.PHONY: build
