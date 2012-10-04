.PHONY: all
.DEFAULT: all

all: build

purge:
	rm -rf src/
	rm -rf bin/.libs
	rm -f bin/file
	rm -f lib/libmagic.so
	rm -f lib/libmagic.so.1
	rm -f lib/libmagic.dylib
	rm -f lib/libmagic.1.dylib

publish: purge
	/usr/bin/env npm -f publish

build:
	tools/build.sh

simpletest:
	tools/test.sh

tests: test
check: test
test: build simpletest

debug:
	tools/debug.sh
