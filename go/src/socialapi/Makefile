# MAKEFLAGS += -j
NO_COLOR=\033[0m
OK_COLOR=\033[0;32m
GODIR=$(CURDIR)/../../../go
GOBINDIR=$(GODIR)/bin
GOPATH := $(realpath $(GODIR))
GOBIN := $(realpath $(GOBINDIR))
CONFIG=./config/dev.toml
MAJOR=0
MINOR=1
# export MAJOR
# export MINOR
EXTRAS?=
# set debug level
debug?=false
ifeq ($(debug), true)
	VERBOSE="-v"
	DBG="-d" # don't use DEBUG, it's set to `yes`
endif

# set config name
ifneq ($(strip $(config)),)
	CONFIG=$(config)
endif

# set port
ifdef port
	PORT="-port=$(port)"
endif

PACKAGES = \
	socialapi/workers/api \
	socialapi/workers/emailnotifier \
	socialapi/workers/dailyemailnotifier \
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
	socialapi/workers/integration \
	socialapi/workers/algoliaconnector


all: testapi

develop: apidev topicfeeddev realtimedev populartopicdev popularpostdev \
	notificationdev trollmodeldev pinnedpostdev algoliaconnectordev \
	emaildev sitemapdev collaborationdev mailsenderdev topicmoderationdev \
	teamdev eventsenderdev integrationdev
minimal: apidev topicfeeddev realtimedev pinnedpostdev
default: configure

apidev:
	@echo "$(OK_COLOR)==> Running API Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/api -watch socialapi -c $(CONFIG) $(PORT) $(DBG) $(EXTRAS)

topicfeeddev:
	@echo "$(OK_COLOR)==> Running Topic Feed Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/topicfeed -watch socialapi/workers/topicfeed -c $(CONFIG) $(DBG) $(EXTRAS)

realtimedev:
	@echo "$(OK_COLOR)==> Running Realtime Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/realtime -watch socialapi/workers/realtime/realtime -c $(CONFIG) $(DBG) $(EXTRAS)

populartopicdev:
	@echo "$(OK_COLOR)==> Running Popular Topics Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/populartopic -watch socialapi/workers/populartopic -c $(CONFIG) $(DBG) $(EXTRAS)

pinnedpostdev:
	@echo "$(OK_COLOR)==> Running PinnedPost Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/pinnedpost -watch socialapi/workers/pinnedpost -c $(CONFIG) $(DBG) $(EXTRAS)

algoliaconnectordev:
	@echo "$(OK_COLOR)==> Running TopicIndex Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/algoliaconnector -watch socialapi/workers/algoliaconnector -c $(CONFIG) $(DBG) $(EXTRAS)

notificationdev:
	@echo "$(OK_COLOR)==> Running Notification Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/notification -watch socialapi/workers/notification -c $(CONFIG) $(DBG) $(EXTRAS)

emaildev: activityemaildev dailyemaildev privatemessageemaildev

activityemaildev:
	@echo "$(OK_COLOR)==> Running Email Notifier Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/email/activityemail -watch socialapi/workers/email/activityemail -c $(CONFIG) $(DBG) $(EXTRAS)

dailyemaildev:
	@echo "$(OK_COLOR)==> Running Daily Email Notifier Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/email/dailyemail -watch socialapi/workers/email/dailyemail -c $(CONFIG) $(DBG) $(EXTRAS)

privatemessageemaildev: privatemessageemailfeederdev privatemessageemailsenderdev

privatemessageemailfeederdev:
	@echo "$(OK_COLOR)==> Running Private Message Email Feeder Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/email/privatemessageemailfeeder -watch socialapi/workers/email/privatemessageemail/privatemessageemailfeeder -c $(CONFIG) $(DBG) $(EXTRAS)

privatemessageemailsenderdev:
	@echo "$(OK_COLOR)==> Running Private Message Email Sender Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/email/privatemessageemailsender -watch socialapi/workers/email/privatemessageemail/privatemessageemailsender -c $(CONFIG) $(DBG) $(EXTRAS)

popularpostdev:
	@echo "$(OK_COLOR)==> Running Popular Posts Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/popularpost -watch socialapi/workers/popularpost -c $(CONFIG) $(DBG) $(EXTRAS)

trollmodeldev:
	@echo "$(OK_COLOR)==> Running Troll Mode Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/trollmode -watch socialapi/workers/trollmode -c $(CONFIG) $(DBG) $(EXTRAS)

dispatcherdev:
	@echo "$(OK_COLOR)==> Running Dispatcher Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/realtime/dispatcher -watch socialapi/workers/realtime/dispatcher -c $(CONFIG) $(DBG) $(EXTRAS)

gatekeeperdev:
	@echo "$(OK_COLOR)==> Running Gatekeeper Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/realtime/gatekeeper -watch socialapi/workers/realtime/gatekeeper -c $(CONFIG) $(DBG) $(EXTRAS)

collaborationdev:
	@echo "$(OK_COLOR)==> Running Collaboration Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/collaboration -watch socialapi/workers/collaboration -kite-init -c $(CONFIG) $(DBG) $(EXTRAS)

mailsenderdev:
	@echo "$(OK_COLOR)==> Running Mailsender Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/email/emailsender -watch socialapi/workers/email/emailsender -c $(CONFIG) $(DBG) $(EXTRAS)


topicmoderationdev:
	@echo "$(OK_COLOR)==> Running Topic Moderation Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/topicmoderation -watch socialapi/workers/moderation -c $(CONFIG) $(DBG) $(EXTRAS)

onfiguremigration:
	(vagrant ssh default --command "mongo localhost/koding --eval='db.relationships.update({},{\$$unset:{migrationStatus:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jNewStatusUpdates.update({},{\$$unset:{socialMessageId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jComments.update({},{\$$unset:{socialMessageId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jTags.update({},{\$$unset:{socialApiChannelId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jAccounts.update({},{\$$unset:{socialApiId:0}},{multi:true})'")

migrate:
	@echo "$(OK_COLOR)==> Running Popular Posts Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/migrator -watch socialapi/workers/migrator/controller -c $(CONFIG) $(DBG) $(EXTRAS)
sitemapdev: sitemapfeederdev sitemapgeneratordev

sitemapfeederdev:
	@echo "$(OK_COLOR)==> Running Sitemap Feeder Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/sitemap/sitemapfeeder -watch socialapi/workers/sitemap/sitemapfeeder -c $(CONFIG) $(DBG) $(EXTRAS)

sitemapgeneratordev:
	@echo "$(OK_COLOR)==> Running Sitemap Generator Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/sitemap/sitemapgenerator -watch socialapi/workers/sitemap/sitemapgenerator -c $(CONFIG) $(DBG) $(EXTRAS)

sitemapinitdev:
	@echo "$(OK_COLOR)==> Running Sitemap Initializer Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/sitemap/sitemapinitializer -watch socialapi/workers/sitemap/sitemapfeeder -c $(CONFIG) $(DBG) $(EXTRAS)

teamdev:
	@echo "$(OK_COLOR)==> Running Team Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/team -watch socialapi/workers/team -c $(CONFIG) $(DBG) $(EXTRAS)

integrationdev: webhookdev middlewaredev

webhookdev:
	@echo "$(OK_COLOR)==> Running Webhook Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/integration/webhook -watch socialapi/workers/integration/webhook -c $(CONFIG) $(DBG) $(EXTRAS)

middlewaredev:
	@echo "$(OK_COLOR)==> Running Webhook Middleware Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/integration/webhookmiddleware -watch github.com/koding/integration -c $(CONFIG) $(DBG) $(EXTRAS)

eventsenderdev:
	@echo "$(OK_COLOR)==> Running Event Sender Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/integration/eventsender -watch socialapi/workers/integration/eventsender -c $(CONFIG) $(DBG) $(EXTRAS)

createdb:
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jAccounts.update({},{\$$unset:{socialApiId:0}},{multi:true})'")
	(vagrant ssh default --command "mongo localhost/koding --eval='db.jGroups.update({},{\$$unset:{socialApiChannelId:0}},{multi:true})'")
	(vagrant ssh default --command "/opt/koding/go/src/socialapi/db/sql/definition/create.sh /opt/koding/go/src/socialapi/db/sql")

configure: install installwatcher install-migrate
	@echo "$(OK_COLOR)==> Configuration is done $(NO_COLOR)"

install-postgres:
	@echo "$(OK_COLOR)==> Installing postgresql"
	(vagrant ssh default --command "/opt/koding/go/src/socialapi/db/sql/definition/install.sh")

installwatcher:
	@`which go` get github.com/canthefason/go-watcher
	@`which go` install github.com/canthefason/go-watcher/cmd/watcher

install-migrate:
	@`which go` get github.com/mattes/migrate
	@`which go` install github.com/mattes/migrate

install:
	@echo $(CONFIG)
	@echo "$(OK_COLOR)==> Installing all packages $(NO_COLOR)"
	@echo "NOTICE: make install is deprecated use ../../build.sh"
	@echo "building with ../../build.sh"
	../../build.sh
test:
	@echo "$(OK_COLOR)==> Testing all packages $(NO_COLOR)"
	@`which go` test $(VERBOSE) ${PACKAGES}

build:
	@echo "$(OK_COLOR)==> Building all packages $(NO_COLOR)"
	@echo "NOTICE: make build is deprecated use ../../build.sh"
	@echo "building with ../../build.sh"
	../../build.sh

testwebhook:
	@echo "$(OK_COLOR)--> webhook model tests... $(NO_COLOR)"
	@`which go` test -c workers/integration/webhook/*.go
	@./webhook.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm  ./webhook.test

	@echo "$(OK_COLOR)--> webhook api tests... $(NO_COLOR)"
	@`which go` test -c workers/integration/webhook/api/*.go
	@./api.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm  ./api.test

	@echo "$(OK_COLOR)--> webhook integration tests... $(NO_COLOR)"
	@`which go` test -c workers/integration/webhook/tests/*.go
	@./tests.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./tests.test

testeventsender:
	@echo "$(OK_COLOR)--> eventsender tests... $(NO_COLOR)"
	@`which go` test -c workers/integration/eventsender/*.go
	@./eventsender.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm  ./eventsender.test

testpermission:
	@echo "$(OK_COLOR)--> permission tests... $(NO_COLOR)"
	@`which go` test -c workers/permission/tests/*.go
	@./permission.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm  ./permission.test

testteam: testteamunit testteamintegration

testteamunit:
	@echo "$(OK_COLOR)--> team unit tests... $(NO_COLOR)"
	@`which go` test -c workers/team/*.go
	@./team.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./team.test

testteamintegration:
	@echo "$(OK_COLOR)--> team integration tests... $(NO_COLOR)"
	@`which go` test -c workers/team/tests/*.go
	@./tests.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./tests.test

testmoderation: testmoderationunit testmoderationintegration

testmoderationunit:
	@echo "$(OK_COLOR)--> moderation unit tests... $(NO_COLOR)"
	@`which go` test -c workers/moderation/topic/*.go
	@./topic.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./topic.test

testmoderationintegration:
	@echo "$(OK_COLOR)--> moderation integration tests... $(NO_COLOR)"
	@`which go` test -c workers/moderation/topic/tests/*.go
	@./tests.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./tests.test

testalgolia:
	@echo "$(OK_COLOR)--> algoliaconnector unit tests... $(NO_COLOR)"
	@`which go` test -c workers/algoliaconnector/algoliaconnector/*.go
	@./algoliaconnector.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./algoliaconnector.test


testtopicfeeed:
	@echo "$(OK_COLOR)--> topic feed tests... $(NO_COLOR)"
	@`which go` test -c workers/topicfeed/*.go
	@./topicfeed.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./topicfeed.test

# testcollaboration runs the unit and integration tests of collaboration worker
testcollaboration:
	@echo "$(OK_COLOR)--> collaboration tests... $(NO_COLOR)"
	@`which go` test -c workers/collaboration/tests/*.go
	@./collaboration.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm  ./collaboration.test

	@`which go` test -c workers/collaboration/*.go
	@./collaboration.test -kite-init $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm  ./collaboration.test

testmodels:
	@echo "$(OK_COLOR)--> model tests... $(NO_COLOR)"
	@`which go` test -c models/*.go
	@./models.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./models.test

testmailsender:
	@echo "$(OK_COLOR)--> Mailsender tests... $(NO_COLOR)"
	@`which go` test -c workers/email/emailsender/*.go
	@./emailsender.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm  ./emailsender.test

testmail:
	@echo "$(OK_COLOR)--> mail tests... $(NO_COLOR)"
	@`which go` test -c workers/email/mailparse/models/*.go
	@./models.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./models.test

	@echo "$(OK_COLOR)--> mail integration tests... $(NO_COLOR)"
	@`which go` test -c workers/email/mailparse/tests/*.go
	@./tests.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./tests.test

testemailworker:
	# @echo "$(OK_COLOR)--> activity email tests.. $(NO_COLOR)"
	# @`which go` test -c workers/email/activityemail/*.go
	# @./activityemail.test $(DBG) $(EXTRAS) -c $(CONFIG)
	# @rm ./activityemail.test

	@echo "$(OK_COLOR)--> notification email tests... $(NO_COLOR)"
	@`which go` test -c workers/email/privatemessageemail/privatemessageemailfeeder/*.go
	@./feeder.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./feeder.test

	@`which go` test -c workers/email/privatemessageemail/privatemessageemailsender/*.go
	@./sender.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./sender.test

	@`which go` test -c workers/email/emailmodels/*.go
	@./emailmodels.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./emailmodels.test

testnotification: testnotificationunit testnotificationintegration

testnotificationintegration:
	@echo "$(OK_COLOR)--> notification tests... $(NO_COLOR)"
	@`which go` test -c workers/notification/tests/*.go
	@./main.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./main.test

testnotificationunit:
	@echo "$(OK_COLOR)--> notification tests... $(NO_COLOR)"
	@`which go` test -c workers/notification/*.go
	@./notification.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./notification.test


testtrollmode:
	@echo "$(OK_COLOR)--> troll mode tests... $(NO_COLOR)"
	@`which go` test workers/trollmode/tests/*.go
	@`which go` test -c workers/trollmode/*.go
	@./trollmode.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm  ./trollmode.test

testpayment:
	@echo "$(OK_COLOR)--> payment tests... $(NO_COLOR)"
	./workers/payment/tests.sh

testintegration:
	@echo "$(OK_COLOR)--> api integration tests... $(NO_COLOR)"
	@`which go` test -c tests/*.go
	@./main.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./main.test

testrealtime:
	@echo "$(OK_COLOR)--> realtime tests... $(NO_COLOR)"
	@`which go` test -c workers/realtime/realtime/*.go
	@./realtime.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./realtime.test

	@echo "$(OK_COLOR)--> realtime model tests... $(NO_COLOR)"
	@`which go` test -c workers/realtime/models/*.go
	@./models.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./models.test


testapi: testcollaboration testmailsender testmail testmodels testemailworker \
	testmoderation testtopicfeeed testnotification testtrollmode \
	testteam testintegration testrealtime testwebhook

	@echo "$(OK_COLOR)==> Running Unit tests $(NO_COLOR)"

	@`which go` test config/*.go $(DBG)

	@echo "$(OK_COLOR)--> all api tests... $(NO_COLOR)"

	@echo "$(OK_COLOR)==> Running Integration tests $(NO_COLOR)"


	@echo "$(OK_COLOR)--> permission tests... $(NO_COLOR)"
	@`which go` test -c workers/permission/tests/*.go
	@./permission.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm  ./permission.test

	@echo "$(OK_COLOR)--> handler tests... $(NO_COLOR)"
	@`which go` test -c workers/common/handler/*.go
	@./handler.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./handler.test

	@echo "$(OK_COLOR)--> sitemap generator tests... $(NO_COLOR)"
	@`which go` test -c workers/sitemap/sitemapgenerator/*.go
	@./generator.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./generator.test

	@echo "$(OK_COLOR)--> sitemap model tests... $(NO_COLOR)"
	@`which go` test workers/sitemap/models/*.go

doc:
	@for package in $(PACKAGES); \
	do \
		(echo "$(OK_COLOR)==> Running godoc for $$package $(NO_COLOR)"); \
		godoc $$package | less; \
	done;

vet:
	@`which go` tool vet -all=true .

pkgs = \
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
