MKFILE_PATH=$(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR=$(dir $(MKFILE_PATH))
CLIENT=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
SCRIPTS=$(CLIENT)/../scripts
RUN=$(CLIENT)/../run

build-prod:
	npm run build:prod

build-dev:
	npm run build:dev

watch-dev:
	npm run watch:dev

all: landing development

dist: landing build-prod

development: bongo_schema node_modules watch-dev

bongo_schema:
	$(RUN) exec $(SCRIPTS)/generate-bongo-schema > $(MKFILE_DIR).schema.json

node_modules:
	$(SCRIPTS)/check-node_modules.sh $(CLIENT) || $(SCRIPTS)/install-npm.sh
	$(SCRIPTS)/check-node_modules.sh landing   || $(SCRIPTS)/install-npm.sh -d landing

landing:
	$(MAKE) -C landing

test:
	$(MAKE) -C test

.PHONY: node_modules bongo_schema landing test
