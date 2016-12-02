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

all: testapi

default: configure

migrate:
	@echo "$(OK_COLOR)==> Running Popular Posts Worker $(NO_COLOR)"
	@$(GOBINDIR)/watcher -run socialapi/workers/cmd/migrator -watch socialapi/workers/migrator/controller -c $(CONFIG) $(DBG) $(EXTRAS)

configure: install
	@echo "$(OK_COLOR)==> Configuration is done $(NO_COLOR)"

install:
	@echo $(CONFIG)
	@echo "$(OK_COLOR)==> Installing all packages $(NO_COLOR)"
	@echo "NOTICE: make install is deprecated use ../../build.sh"
	@echo "building with ../../build.sh"
	../../build.sh

build:
	@echo "$(OK_COLOR)==> Building all packages $(NO_COLOR)"
	@echo "NOTICE: make build is deprecated use ../../build.sh"
	@echo "building with ../../build.sh"
	../../build.sh

testpresence:
	@echo "$(OK_COLOR)--> presence tests... $(NO_COLOR)"
	@`which go` test -race -c workers/presence/*.go
	@./presence.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./presence.test
	@echo "$(OK_COLOR)--> presence api tests... $(NO_COLOR)"
	@`which go` test -race -c workers/presence/api/*.go
	@./api.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./api.test
	@echo "$(OK_COLOR)--> presence client tests... $(NO_COLOR)"
	@`which go` test -race -c workers/presence/client/*.go
	@./client.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./client.test

testeventsender:
	@echo "$(OK_COLOR)--> eventsender tests... $(NO_COLOR)"
	@`which go` test -c workers/integration/eventsender/*.go
	@./eventsender.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm  ./eventsender.test

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

testalgolia:
	@echo "$(OK_COLOR)--> algoliaconnector unit tests... $(NO_COLOR)"
	@`which go` test -c workers/algoliaconnector/algoliaconnector/*.go
	@./algoliaconnector.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./algoliaconnector.test

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


testapi: testcollaboration testmailsender testmail testmodels \
	testnotification \
	testteam testintegration testrealtime testpresence \
	testpayment

	@echo "$(OK_COLOR)==> Running Unit tests $(NO_COLOR)"

	@`which go` test config/*.go $(DBG)

	@echo "$(OK_COLOR)--> all api tests... $(NO_COLOR)"

	@echo "$(OK_COLOR)==> Running Integration tests $(NO_COLOR)"

	@echo "$(OK_COLOR)--> handler tests... $(NO_COLOR)"
	@`which go` test -c workers/common/handler/*.go
	@./handler.test $(DBG) $(EXTRAS) -c $(CONFIG)
	@rm ./handler.test
