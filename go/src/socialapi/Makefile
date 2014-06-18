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

develop: apidev topicfeeddev realtimedev followingfeeddev populartopicdev popularpostdev notificationdev trollmodeldev runkoding

runkoding:
	(cd /opt/koding && cake -c kodingme -r kodingme run)

default: configure

apidev:
	@echo "$(OK_COLOR)==> Running API Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/api -c $(CONFIG) -d
topicfeeddev:
	@echo "$(OK_COLOR)==> Running Topic Feed Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/topicfeed -c $(CONFIG) -d
realtimedev:
	@echo "$(OK_COLOR)==> Running Realtime Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/realtime -c $(CONFIG)  -d
followingfeeddev:
	@echo "$(OK_COLOR)==> Running Following Feed Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/followingfeed -c $(CONFIG) -d
populartopicdev:
	@echo "$(OK_COLOR)==> Running Popular Topics Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/populartopic -c $(CONFIG) -d

notificationdev:
	@echo "$(OK_COLOR)==> Running Notification Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/notification -c $(CONFIG) -d

emailnotifierdev:
	@echo "$(OK_COLOR)==> Running Email Notifier Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/emailnotifier -c $(CONFIG) -d

dailyemailnotifierdev:
	@echo "$(OK_COLOR)==> Running Daily Email Notifier Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/dailyemailnotifier -c $(CONFIG) -d

popularpostdev:
	@echo "$(OK_COLOR)==> Running Popular Posts Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/popularpost -c $(CONFIG) -d

trollmodeldev:
	@echo "$(OK_COLOR)==> Running Troll Mode Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/trollmode -c $(CONFIG) -d

configuremigration:
	(vagrant ssh default --command "mongo localhost/koding --eval='db.relationships.update({},{\$$unset:{migrationStatus:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jNewStatusUpdates.update({},{\$$unset:{socialMessageId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jComments.update({},{\$$unset:{socialMessageId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jTags.update({},{\$$unset:{socialApiChannelId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jAccounts.update({},{\$$unset:{socialApiId:0}},{multi:true})'")

migrate:
	@echo "$(OK_COLOR)==> Running Popular Posts Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/migrator -c $(CONFIG) -d

sitemapfeederdev:
	@echo "$(OK_COLOR)==> Running Sitemap Feeder Worker $(NO_COLOR)"
	@$(GOBINDIR)/rerun socialapi/workers/sitemap/sitemapfeeder -c $(CONFIG) -d

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
	socialapi/workers/sitemap/sitemapfeeder

default: all

createdb:
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jAccounts.update({},{\$$unset:{socialApiId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jGroups.update({},{\$$unset:{socialApiChannelId:0}},{multi:true})'")
	(vagrant ssh default --command "/opt/koding/go/src/socialapi/db/sql/definition/create.sh")

configure: install installrerun
	@echo "$(OK_COLOR)==> Configuration is done $(NO_COLOR)"

installrerun:
	@go get github.com/skelterjohn/rerun
	@go install github.com/skelterjohn/rerun

install:
	@echo "$(OK_COLOR)==> Installing all packages $(NO_COLOR)"
	@go install -v ${PACKAGES}

test:
	@echo "$(OK_COLOR)==> Testing all packages $(NO_COLOR)"
	@go test -v ${PACKAGES}

build:
	@echo "$(OK_COLOR)==> Building all packages $(NO_COLOR)"
	@go build -v ${PACKAGES}

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
