all:

jshint:
	find lib/ -name '*.js' | xargs ./node_modules/.bin/jshint
	find examples/ -name '*.js' | xargs ./node_modules/.bin/jshint

clean:
	find . -name '*~' -exec rm {} ';'

.PHONY: clean
