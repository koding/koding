BIN=./node_modules/.bin

.PHONY: landing

all: landing
	@DEBUG=client:*,bant:* $(BIN)/gulp --devMode --watchMode

scripts:
	@DEBUG=client:*,bant:* $(BIN)/gulp scripts --devMode --watchMode

build: landing
	@DEBUG=client:* $(BIN)/gulp

shrinkwrap:
	@$(BIN)/npm-shrinkwrap

landing:
	@cd landing && npm install --unsafe-perm --silent
	@cd landing && rm -rf node_modules/gulp.spritesmith/node_modules/spritesmith/node_modules/canvassmith
	@cd landing && $(BIN)/gulp build-all-sites --koding-version=$(git rev-parse HEAD)
	@cd landing && rsync -av static/a/ ../../website/a/
