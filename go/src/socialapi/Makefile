# MAKEFLAGS += -j
NO_COLOR=\033[0m
OK_COLOR=\033[0;32m
GODIR=$(CURDIR)/../../../go
GOBINDIR=$(GODIR)/bin
GOPATH := $(realpath $(GODIR))
GOBIN := $(realpath $(GOBINDIR))
CONFIG=./config/vagrant.toml
MAJOR=0
MINOR=1
# export MAJOR
# export MINOR

# set debug level
debug?=false
ifeq ($(debug), true)
	VERBOSE="-v"
	DEBUG="-d"
endif

# set config name
ifneq ($(strip $(config)),)
	CONFIG=$(config)
endif

PACKAGES = \
	socialapi/workers/api \
	socialapi/workers/emailnotifier \
	socialapi/workers/dailyemailnotifier \
	socialapi/workers/followingfeed \
	socialapi/workers/notification \
	socialapi/workers/popularpost \
	socialapi/workers/trollmode \
	socialapi/workers/populartopic \
	socialapi/workers/realtime \
	socialapi/workers/topicfeed \
	socialapi/workers/migrator \
	socialapi/workers/sitemap/sitemapfeeder \
	socialapi/workers/sitemap/sitemapgenerator \
	socialapi/workers/sitemap/sitemapinitializer \
 	socialapi/workers/sitemap/sitemaprootgenerator

all: testapi

develop: apidev topicfeeddev realtimedev followingfeeddev populartopicdev popularpostdev notificationdev trollmodeldev
default: configure

apidev:
	@echo $(debug)
	@echo $(DEBUG)
	@echo "$(OK_COLOR)==> Running API Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/api -c $(CONFIG) $(DEBUG)
topicfeeddev:
	@echo "$(OK_COLOR)==> Running Topic Feed Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/topicfeed -c $(CONFIG) $(DEBUG)
realtimedev:
	@echo "$(OK_COLOR)==> Running Realtime Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/realtime -c $(CONFIG) $(DEBUG)
followingfeeddev:
	@echo "$(OK_COLOR)==> Running Following Feed Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/followingfeed -c $(CONFIG) $(DEBUG)
populartopicdev:
	@echo "$(OK_COLOR)==> Running Popular Topics Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/populartopic -c $(CONFIG) $(DEBUG)

notificationdev:
	@echo "$(OK_COLOR)==> Running Notification Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/notification -c $(CONFIG) $(DEBUG)

emailnotifierdev:
	@echo "$(OK_COLOR)==> Running Email Notifier Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/emailnotifier -c $(CONFIG) $(DEBUG)

dailyemailnotifierdev:
	@echo "$(OK_COLOR)==> Running Daily Email Notifier Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/dailyemailnotifier -c $(CONFIG) $(DEBUG)

popularpostdev:
	@echo "$(OK_COLOR)==> Running Popular Posts Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/popularpost -c $(CONFIG) $(DEBUG)

trollmodeldev:
	@echo "$(OK_COLOR)==> Running Troll Mode Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/trollmode -c $(CONFIG) $(DEBUG)

configuremigration:
	(vagrant ssh default --command "mongo localhost/koding --eval='db.relationships.update({},{\$$unset:{migrationStatus:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jNewStatusUpdates.update({},{\$$unset:{socialMessageId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jComments.update({},{\$$unset:{socialMessageId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jTags.update({},{\$$unset:{socialApiChannelId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jAccounts.update({},{\$$unset:{socialApiId:0}},{multi:true})'")

migrate:
	@echo "$(OK_COLOR)==> Running Popular Posts Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/migrator -c $(CONFIG) $(DEBUG)

sitemapfeederdev:
	@echo "$(OK_COLOR)==> Running Sitemap Feeder Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/sitemap/sitemapfeeder -c $(CONFIG) $(DEBUG)

sitemapgeneratordev:
	@echo "$(OK_COLOR)==> Running Sitemap Generator Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/sitemap/sitemapgenerator -c $(CONFIG) $(DEBUG)

sitemapinitdev:
	@echo "$(OK_COLOR)==> Running Sitemap Initializer Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/sitemap/sitemapinitializer -c $(CONFIG) $(DEBUG)

sitemaprootgeneratordev:
	@echo "$(OK_COLOR)==> Running Sitemap Root Generator Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/sitemap/sitemaprootgenerator -c $(CONFIG) $(DEBUG)

createdb:
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jAccounts.update({},{\$$unset:{socialApiId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jGroups.update({},{\$$unset:{socialApiChannelId:0}},{multi:true})'")
	(vagrant ssh default --command "/opt/koding/go/src/socialapi/db/sql/definition/create.sh /opt/koding/go/src/socialapi/db/sql")

configure: install installrerun
	@echo "$(OK_COLOR)==> Configuration is done $(NO_COLOR)"

installrerun:
	@go get github.com/skelterjohn/rerun
	@go install github.com/skelterjohn/rerun

install:
	@echo $(CONFIG)
	@echo "$(OK_COLOR)==> Installing all packages $(NO_COLOR)"
	@go install $(VERBOSE) ${PACKAGES}

test:
	@echo "$(OK_COLOR)==> Testing all packages $(NO_COLOR)"
	@go test $(VERBOSE) ${PACKAGES}

build:
	@echo "$(OK_COLOR)==> Building all packages $(NO_COLOR)"
	@go build $(VERBOSE) ${PACKAGES}

testapi:
	@echo "$(OK_COLOR)==> Running go api tests $(NO_COLOR)"
	@go test tests/*.go
	@go test workers/notification/tests/*.go

doc:
	@for package in $(PACKAGES); \
	do \
		(echo "$(OK_COLOR)==> Running godoc for $$package $(NO_COLOR)"); \
		godoc $$package | less; \
	done;

vet:
	@`which go` tool vet -all=true .

pkgs = \
	followingfeed \
	realtime \
	rerun \
	topicfeed \
	notification

dep:
	@echo "$(OK_COLOR)==> Copying files $(NO_COLOR)";
	@for pkg in $(pkgs); \
	do \
	TMP=/tmp/socialapi; \
	OUTFOLDER=$$TMP/out; \
	CONTENTFOLDER=$$TMP/$$pkg; \
	ZIPNAME=$$OUTFOLDER/$$pkg-$(MAJOR).$(MINOR).tar; \
	mkdir -p $$TMP; \
	mkdir -p $$OUTFOLDER; \
	rm -rf $$CONTENTFOLDER; \
	mkdir $$CONTENTFOLDER; \
	cp $(GOBINDIR)/$$pkg $$CONTENTFOLDER ;\
	cp $(CONFIG) $$CONTENTFOLDER ;\
    done;

	@echo "$(OK_COLOR)==> Generating TAR files $(NO_COLOR)";
	@for pkg in $(pkgs); \
	do \
	TMP=/tmp/socialapi; \
	OUTFOLDER=$$TMP/out; \
	CONTENTFOLDER=$$TMP/$$pkg; \
	ZIPNAME=$$OUTFOLDER/$$pkg-$(MAJOR).$(MINOR).tar; \
    echo "Creating" $$ZIPNAME ;\
	cd $$TMP && tar cof $$ZIPNAME ./$$pkg; \
	done;

	@echo "$(OK_COLOR)==> Files are located at files $(NO_COLOR)";
