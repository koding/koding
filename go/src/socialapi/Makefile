# MAKEFLAGS += -j
NO_COLOR=\033[0m
OK_COLOR=\033[0;32m
GODIR=$(CURDIR)/../../../go
KODINGDIR=$(GODIR)/..
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
	@$(KODINGDIR)/scripts/gotests.sh socialapi socialapi/workers/presence/...

testteam: testteamunit testteamintegration

testteamunit:
	@echo "$(OK_COLOR)--> team unit tests... $(NO_COLOR)"
	@$(KODINGDIR)/scripts/gotests.sh socialapi socialapi/workers/team

testteamintegration:
	@echo "$(OK_COLOR)--> team integration tests... $(NO_COLOR)"
	@$(KODINGDIR)/scripts/gotests.sh socialapi socialapi/workers/team/tests

# testcollaboration runs the unit and integration tests of collaboration worker
testcollaboration:
	@echo "$(OK_COLOR)--> collaboration tests... $(NO_COLOR)"
	@$(KODINGDIR)/scripts/gotests.sh socialapi socialapi/workers/collaboration/tests

	env RUN_FLAGS="-kite-init -c=./go/src/socialapi/config/dev.toml" $(KODINGDIR)/scripts/gotests.sh socialapi socialapi/workers/collaboration

testmodels:
	@echo "$(OK_COLOR)--> model tests... $(NO_COLOR)"
	@$(KODINGDIR)/scripts/gotests.sh socialapi socialapi/models

testmailsender:
	@echo "$(OK_COLOR)--> Mailsender tests... $(NO_COLOR)"
	@$(KODINGDIR)/scripts/gotests.sh socialapi socialapi/workers/email/emailsender

testmail:
	@echo "$(OK_COLOR)--> mail tests... $(NO_COLOR)"
	@$(KODINGDIR)/scripts/gotests.sh socialapi socialapi/workers/email/mailparse/models

	@echo "$(OK_COLOR)--> mail integration tests... $(NO_COLOR)"
	@$(KODINGDIR)/scripts/gotests.sh socialapi socialapi/workers/email/mailparse/tests

# testpayments includes -race & -v flags
testpayment:
	@echo "$(OK_COLOR)--> payment tests... $(NO_COLOR)"
	$(KODINGDIR)/scripts/gotests.sh socialapi socialapi/workers/payment/...

testintegration:
	@echo "$(OK_COLOR)--> api integration tests... $(NO_COLOR)"
	@$(KODINGDIR)/scripts/gotests.sh socialapi socialapi/tests

testrealtime:
	@echo "$(OK_COLOR)--> realtime tests... $(NO_COLOR)"
	@$(KODINGDIR)/scripts/gotests.sh socialapi socialapi/workers/realtime/realtime

	@echo "$(OK_COLOR)--> realtime model tests... $(NO_COLOR)"
	@$(KODINGDIR)/scripts/gotests.sh socialapi socialapi/workers/realtime/models


testapi: testcollaboration testmailsender testmail testmodels \
	testteam testintegration testrealtime testpresence \
	testpayment

	@echo "$(OK_COLOR)==> Running Unit tests $(NO_COLOR)"

	@`which go` test config/*.go $(DBG)

	@echo "$(OK_COLOR)--> all api tests... $(NO_COLOR)"

	@echo "$(OK_COLOR)==> Running Integration tests $(NO_COLOR)"

	@echo "$(OK_COLOR)--> handler tests... $(NO_COLOR)"
	@$(KODINGDIR)/scripts/gotests.sh socialapi socialapi/workers/common/handler
