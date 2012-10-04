.PHONY: all
.DEFAULT: all

all:
	/usr/bin/env npm install

lint:
	tools/lint.sh

pclean:
	cp config/package.json package.json

purge: clean
clean: pclean
	rm -rf node_modules
	rm -f config/dependencies.js

publish: clean
	/usr/bin/env npm publish

tests: test
check: test
test: lint
	$(MAKE) test-default
	$(MAKE) test-xml2js
	$(MAKE) test-mime
	$(MAKE) test-nobinary

test-default: purge
	@npm install > /dev/null 2>&1
	tools/test.sh

test-xml2js: purge
	@npm install --xml2js true > /dev/null 2>&1
	tools/test.sh

test-mime: purge
	@npm install --mime true > /dev/null 2>&1
	tools/test.sh

test-nobinary: purge
	@npm install --xml2js true --mime true > /dev/null 2>&1
	tools/test.sh

simpletest: lint
	tools/test.sh
