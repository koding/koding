MKFILE_PATH=$(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR=$(dir $(MKFILE_PATH))
BUILDER=$(MKFILE_DIR)builder/bin/cmd.coffee
BASEDIR?=--basedir "$(MKFILE_DIR)"
BASEURL?=--baseurl "/a/p/p"
USE?=--use "$(MKFILE_DIR)*/bant.json"
GLOBALS?=--globals-file "$(MKFILE_DIR)globals.coffee"
CONFIG?=--config-file "$(MKFILE_DIR).client-config.json"
OUTDIR?=--outdir "$(MKFILE_DIR)../website/a/p/p/"
THIRDPARTY_DIR?=--thirdparty-dir "$(MKFILE_DIR)thirdparty"
ASSETS_DIR?=--assets-dir "$(MKFILE_DIR)assets"
EXTRAS?=
BUILDER_ARGS=\
	$(BASEDIR) \
	$(BASEURL) \
	$(USE) \
	$(GLOBALS) \
	$(CONFIG) \
	$(ASSETS_DIR) \
	$(THIRDPARTY_DIR) \
	$(OUTDIR) \
	$(EXTRAS)
BUILDER_DEBUG_FLAGS?=--debug-js --debug-css
BUILDER_WATCH_FLAGS?=--watch-js --watch-css --watch-sprites
BUILDER_MINIFY_FLAGS?=--minify-css --minify-js
BUILDER_EXT_SOURCEMAPS_FLAGS?=--extract-js-sourcemaps --debug-js

all: landing development

vanilla:
	@$(BUILDER) $(BUILDER_ARGS)

debug:
	$(BUILDER) -v $(BUILDER_DEBUG_FLAGS) $(BUILDER_ARGS)

watch:
	@$(BUILDER) -v $(BUILDER_WATCH_FLAGS) $(BUILDER_ARGS)

development:
	@$(BUILDER) -v $(BUILDER_DEBUG_FLAGS) $(BUILDER_WATCH_FLAGS) $(BUILDER_ARGS)

minify-with-external-sourcemaps:
	@$(BUILDER)  \
		$(BUILDER_MINIFY_FLAGS) \
		$(BUILDER_EXT_SOURCEMAPS_FLAGS) \
		$(BUILDER_ARGS)

minify:
	@$(BUILDER) $(BUILDER_MINIFY_FLAGS) $(BUILDER_ARGS)

landing:
	@$(MAKE) -C landing

.PHONY: landing
