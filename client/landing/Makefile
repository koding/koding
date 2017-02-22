all: build

build:
	@node_modules/.bin/gulp build-all-sites
	@rsync -av static/a/ ../../website/a/

dev:
	@node_modules/.bin/gulp --cwd site.landing --exportDir=./../../../website/a/site.landing/ --devMode
