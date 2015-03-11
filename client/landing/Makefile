BIN=./node_modules/.bin
REV=$(shell git rev-parse HEAD)

all:
	@$(BIN)/gulp build-all-sites --koding-version=$(REV)
	@rsync -av static/a/ ../../website/a/
