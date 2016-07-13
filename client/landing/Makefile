dev:
	@gulp --cwd site.landing --exportDir=./../../../website/a/site.landing/ --devMode

all:
	@gulp build-all-sites
	@rsync -av static/a/ ../../website/a/
