DIR=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
SCRIPTS=$(DIR)/../../scripts

all: node_modules build

node_modules:
	$(SCRIPTS)/check-node_modules.sh || npm install

build:
	@node_modules/.bin/gulp build-all-sites
	@rsync -av static/a/ ../../website/a/

dev:
	@node_modules/.bin/gulp --cwd site.landing --exportDir=./../../../website/a/site.landing/ --devMode
