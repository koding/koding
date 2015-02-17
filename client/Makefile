BIN=./node_modules/.bin

.PHONY: landing

all:
	@clear
	@DEBUG=client:* $(BIN)/gulp --devMode

scripts:
	@clear
	@DEBUG=client:* $(BIN)/gulp scripts --devMode

build: landing
	@DEBUG=client:* $(BIN)/gulp

landing:
	@cd landing && npm install --unsafe-perm --silent
	@cd landing && rm -rf node_modules/gulp.spritesmith/node_modules/spritesmith/node_modules/canvassmith
	@cd landing && gulp build-all-sites --koding-version=$(git rev-parse HEAD)
	@cd landing && rsync -av static/a/ ../../website/a/
