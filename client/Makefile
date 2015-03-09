MKFILE_PATH=$(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR=$(dir $(MKFILE_PATH))
BUILDER=$(MKFILE_DIR)builder/bin/cmd.coffee
BASEDIR?=--basedir "$(MKFILE_DIR)"
BASEURL?=--baseurl "/a/p/p"
USE?=--use "$(MKFILE_DIR)*/bant.json"
GLOBALS?=--globals-file "$(MKFILE_DIR)globals.coffee"
CONFIG?=--config-file "$(MKFILE_DIR).client-config.json"
OUTDIR=$(MKFILE_DIR)../website/a/p/p/
JS_OUTFILE?=--js-outfile "$(OUTDIR)bundle.js"
CSS_OUTDIR?=--css-outdir "$(OUTDIR)"
ASSETS_OUTDIR?=--assets-outdir "$(OUTDIR)assets"
THIRDPARTY_OUTDIR?=--thirdparty-outdir "$(OUTDIR)thirdparty"
THIRDPARTY_DIR?=--thirdparty-dir "$(MKFILE_DIR)thirdparty"
ASSETS_DIR?=--assets-dir "$(MKFILE_DIR)assets"
EXTRAS?=
BUILDER_ARGS=\
	$(BASEDIR) \
	$(BASEURL) \
	$(USE) \
	$(GLOBALS) \
	$(CONFIG) \
	$(JS_OUTFILE) \
	$(CSS_OUTDIR) \
	$(ASSETS_DIR) \
	$(ASSETS_OUTDIR) \
	$(THIRDPARTY_DIR) \
	$(THIRDPARTY_OUTDIR) \
	$(EXTRAS)
BUILDER_DEBUG_FLAGS?=--debug-js --debug-css
BUILDER_WATCH_FLAGS?=--watch-js --watch-css
BUILDER_MINIFY_FLAGS?=--minify-css --minify-js
BUILDER_EXT_SOURCEMAPS_FLAGS?=--extract-js-sourcemaps --debug-js

all: client landing

client:
	@$(BUILDER) $(BUILDER_ARGS) $(BUILDER_MINIFY_FLAGS)

dev:
	$(BUILDER) -v $(BUILDER_ARGS) $(BUILDER_DEBUG_FLAGS)

watch:
	@$(BUILDER) -v $(BUILDER_ARGS) $(BUILDER_DEBUG_FLAGS) $(BUILDER_WATCH_FLAGS)

watch-no-debug:
	@$(BUILDER) -v $(BUILDER_ARGS) $(BUILDER_WATCH_FLAGS)

extract-sourcemaps:
	@$(BUILDER) $(BUILDER_ARGS) \
		$(BUILDER_MINIFY_FLAGS) \
		$(BUILDER_EXT_SOURCEMAPS_FLAGS)

landing:
	@cd landing && npm install --unsafe-perm --silent
	@cd landing && rm -rf node_modules/gulp.spritesmith/node_modules/spritesmith/node_modules/canvassmith
	@cd landing && $(BIN)/gulp build-all-sites --koding-version=$(git rev-parse HEAD)
	@cd landing && rsync -av static/a/ ../../website/a/

.PHONY: landing
