MOCHA_OPTS=-t 4000 test/*/*/*-test.js test/*/*/*/*-test.js
REPORTER = spec

check: test

test: test-unit

test-unit:
	@NODE_ENV=test MOCK=on ./node_modules/.bin/mocha \
	    --reporter $(REPORTER) \
		$(MOCHA_OPTS)

lib-cov:
	jscoverage --encoding=UTF-8 lib lib-cov

test-cov:	lib-cov
	mv lib lib-bak
	mv lib-cov lib
	$(MAKE) test REPORTER=html-cov > coverage.html
	rm -rf lib
	mv lib-bak lib

test-coveralls:	lib-cov
	echo TRAVIS_JOB_ID $(TRAVIS_JOB_ID)
	mv lib lib-bak
	mv lib-cov lib
	$(MAKE) test REPORTER=mocha-lcov-reporter > pkgcloud.lcov.raw
	rm -rf lib
	mv lib-bak lib
	sed "s#SF:#SF:$(PWD)/lib/#g" pkgcloud.lcov.raw > pkgcloud.lcov
	./node_modules/coveralls/bin/coveralls.js < pkgcloud.lcov
	rm pkgcloud.lcov pkgcloud.lcov.raw

.PHONY: test
