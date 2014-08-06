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
	DBG="-d" # don't use DEBUG, it's set to `yes`
endif

outputMetrics?=false
ifeq ($(outputMetrics), true)
	METRICS="-outputMetrics"
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
	socialapi/workers/pinnedpost \
	socialapi/workers/popularpost \
	socialapi/workers/trollmode \
	socialapi/workers/populartopic \
	socialapi/workers/realtime \
	socialapi/workers/topicfeed \
	socialapi/workers/migrator \
	socialapi/workers/sitemap/sitemapfeeder \
	socialapi/workers/sitemap/sitemapgenerator \
	socialapi/workers/sitemap/sitemapinitializer \
	socialapi/workers/algoliaconnector

all: testapi

develop: apidev topicfeeddev realtimedev followingfeeddev populartopicdev popularpostdev notificationdev trollmodeldev pinnedpostdev algoliaconnectordev
minimal: apidev topicfeeddev realtimedev pinnedpostdev
default: configure

apidev:
	@echo "DBG $(DBG) METRICS ====> $(METRICS)"
	@echo "$(OK_COLOR)==> Running API Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/api -c $(CONFIG) $(DBG) $(METRICS)
topicfeeddev:
	@echo "$(OK_COLOR)==> Running Topic Feed Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/topicfeed -c $(CONFIG) $(DBG) $(METRICS)
realtimedev:
	@echo "$(OK_COLOR)==> Running Realtime Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/realtime -c $(CONFIG) $(DBG) $(METRICS)
followingfeeddev:
	@echo "$(OK_COLOR)==> Running Following Feed Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/followingfeed -c $(CONFIG) $(DBG) $(METRICS)
populartopicdev:
	@echo "$(OK_COLOR)==> Running Popular Topics Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/populartopic -c $(CONFIG) $(DBG) $(METRICS)

pinnedpostdev:
	@echo "$(OK_COLOR)==> Running PinnedPost Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/pinnedpost -c $(CONFIG) $(DBG) $(METRICS)

algoliaconnectordev:
	@echo "$(OK_COLOR)==> Running TopicIndex Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/algoliaconnector -c $(CONFIG) $(DBG) $(METRICS)

notificationdev:
	@echo "$(OK_COLOR)==> Running Notification Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/notification -c $(CONFIG) $(DBG) $(METRICS)

emailnotifierdev:
	@echo "$(OK_COLOR)==> Running Email Notifier Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/emailnotifier -c $(CONFIG) $(DBG) $(METRICS)

dailyemailnotifierdev:
	@echo "$(OK_COLOR)==> Running Daily Email Notifier Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/dailyemailnotifier -c $(CONFIG) $(DBG) $(METRICS)

popularpostdev:
	@echo "$(OK_COLOR)==> Running Popular Posts Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/popularpost -c $(CONFIG) $(DBG) $(METRICS)

trollmodeldev:
	@echo "$(OK_COLOR)==> Running Troll Mode Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/trollmode -c $(CONFIG) $(DBG) $(METRICS)

configuremigration:
	(vagrant ssh default --command "mongo localhost/koding --eval='db.relationships.update({},{\$$unset:{migrationStatus:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jNewStatusUpdates.update({},{\$$unset:{socialMessageId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jComments.update({},{\$$unset:{socialMessageId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jTags.update({},{\$$unset:{socialApiChannelId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jAccounts.update({},{\$$unset:{socialApiId:0}},{multi:true})'")

migrate:
	@echo "$(OK_COLOR)==> Running Popular Posts Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/migrator -c $(CONFIG) $(DBG) $(METRICS)

sitemapdev: sitemapfeederdev sitemapgeneratordev

sitemapfeederdev:
	@echo "$(OK_COLOR)==> Running Sitemap Feeder Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/sitemap/sitemapfeeder -c $(CONFIG) $(DBG) $(METRICS)

sitemapgeneratordev:
	@echo "$(OK_COLOR)==> Running Sitemap Generator Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/sitemap/sitemapgenerator -c $(CONFIG) $(DBG) $(METRICS)

sitemapinitdev:
	@echo "$(OK_COLOR)==> Running Sitemap Initializer Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/sitemap/sitemapinitializer -c $(CONFIG) $(DBG) $(METRICS)

sitemaprootgeneratordev:
	@echo "$(OK_COLOR)==> Running Sitemap Root Generator Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/sitemap/sitemaprootgenerator -c $(CONFIG) $(DBG) $(METRICS)

createdb:
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jAccounts.update({},{\$$unset:{socialApiId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jGroups.update({},{\$$unset:{socialApiChannelId:0}},{multi:true})'")
	(vagrant ssh default --command "/opt/koding/go/src/socialapi/db/sql/definition/create.sh /opt/koding/go/src/socialapi/db/sql")

configure: install-postgres install installrerun
	@echo "$(OK_COLOR)==> Configuration is done $(NO_COLOR)"

install-postgres:
	@echo "$(OK_COLOR)==> Installing postgresql"
	(vagrant ssh default --command "/opt/koding/go/src/socialapi/db/sql/definition/install.sh")

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
	@echo "$(OK_COLOR)==> Running Unit tests $(NO_COLOR)"
	@echo "$(OK_COLOR)--> model tests... $(NO_COLOR)"
	@go test -c models/*.go
	@./models.test $(DBG) $(METRICS) -c ./config/vagrant.toml
	@rm ./models.test

	@echo "$(OK_COLOR)--> api tests... $(NO_COLOR)"
	@go test -c workers/algoliaconnector/algoliaconnector/*.go
	@./algoliaconnector.test -c ./config/test.toml
	@rm ./algoliaconnector.test

	@echo "$(OK_COLOR)==> Running Integration tests $(NO_COLOR)"
	@echo "$(OK_COLOR)--> troll mode tests... $(NO_COLOR)"
	@go test workers/trollmode/tests/*.go
	@go test -c workers/trollmode/trollmode/*.go
	@./trollmode.test $(DBG) $(METRICS) -c ./config/vagrant.toml
	@rm  ./trollmode.test

	@echo "$(OK_COLOR)--> api tests... $(NO_COLOR)"
	@go test -c tests/*.go
	@./main.test
	@rm ./main.test

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
