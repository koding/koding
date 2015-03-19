MKFILE_PATH=$(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR=$(dir $(MKFILE_PATH))
BUILDER=$(MKFILE_DIR)builder/bin/cmd.coffee
BUILDER_BASEDIR?=--basedir "$(MKFILE_DIR)"
BUILDER_BASEURL?=--baseurl "/a/p/p"
BUILDER_USE?=--use "$(MKFILE_DIR)*/bant.json"
BUILDER_GLOBALS?=--globals-file "$(MKFILE_DIR)globals.coffee"
BUILDER_CONFIG?=--config-file "$(MKFILE_DIR).config.json"
BUILDER_OUTDIR?=--outdir "$(MKFILE_DIR)../website/a/p/p/"
BUILDER_THIRDPARTY_DIR?=--thirdparty-dir "$(MKFILE_DIR)thirdparty"
BUILDER_ASSETS_DIR?=--assets-dir "$(MKFILE_DIR)assets"
EXTRAS?=
BUILDER_ARGS=\
	$(BUILDER_BASEDIR) \
	$(BUILDER_BASEURL) \
	$(BUILDER_USE) \
	$(BUILDER_GLOBALS) \
	$(BUILDER_CONFIG) \
	$(BUILDER_ASSETS_DIR) \
	$(BUILDER_THIRDPARTY_DIR) \
	$(BUILDER_OUTDIR) \
	$(EXTRAS)
BUILDER_DEBUG_FLAGS?=--debug-js --debug-css
BUILDER_WATCH_FLAGS?=--watch-js --watch-css --watch-sprites
BUILDER_MINIFY_FLAGS?=--minify-css --minify-js
BUILDER_EXT_SOURCEMAPS_FLAGS?=--extract-js-sourcemaps --debug-js

all: landing development

dist: landing minify-with-external-sourcemaps

vanilla:
	$(BUILDER) $(BUILDER_ARGS)

debug:
	$(BUILDER) -v $(BUILDER_DEBUG_FLAGS) $(BUILDER_ARGS)

watch:
	$(BUILDER) -v $(BUILDER_WATCH_FLAGS) $(BUILDER_ARGS)

development: watch

minify-with-external-sourcemaps:
	$(BUILDER) -v \
		$(BUILDER_MINIFY_FLAGS) \
		$(BUILDER_EXT_SOURCEMAPS_FLAGS) \
		$(BUILDER_ARGS)

minify:
	$(BUILDER) $(BUILDER_MINIFY_FLAGS) $(BUILDER_ARGS)

landing:
	$(MAKE) -C landing

test:
	$(MAKE) -C test

.PHONY: landing test
