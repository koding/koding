MKFILE_PATH=$(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR=$(dir $(MKFILE_PATH))
CLIENT=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
SCRIPTS=$(CLIENT)/../scripts
RUN=$(CLIENT)/../run

all: landing development

build-prod:
	npm run build:prod

build-dev:
	npm run build:dev

watch-dev:
	npm run watch:dev

development: node_modules bongo_schema watch-dev

dist: node_modules bongo_schema landing build-prod

bongo_schema:
	$(RUN) exec $(SCRIPTS)/generate-bongo-schema --file $(MKFILE_DIR).schema.json

node_modules:
	$(SCRIPTS)/check-node_modules.sh $(CLIENT) || npm install

landing:
	$(MAKE) -C landing

test:
	$(MAKE) -C test

.PHONY: node_modules bongo_schema landing test
