BIN=./node_modules/.bin
DEBUG_TARGETS?=client:*,bant:*
GULP_ARGS=
ifeq ($(watch),1)
	GULP_ARGS+=--watchMode
endif
ifeq ($(debug),1)
	GULP_ARGS+=--devMode
endif

all: 
	@DEBUG=$(DEBUG_TARGETS) $(BIN)/gulp $(GULP_ARGS)

scripts:
	@DEBUG=$(DEBUG_TARGETS) $(BIN)/gulp scripts $(GULP_ARGS)

landing:
	@$(MAKE) -C landing all

.PHONY: landing
