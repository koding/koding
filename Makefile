HOST?=localhost
PORT?=8090

KLIENT_DIR=$(KONFIG_PROJECTROOT)/website/a/klient/$(KONFIG_ENVIRONMENT)/latest

# all: configure run

configure:
	@./configure --host "$(HOST):$(PORT)"

run:
	@./run

backend: configure
	@./run backend

services: configure
	@./run services

buildservices:
	@./run buildservices

buildclient: configure
	@./run buildclient

klient:
	@mkdir --parents $(KLIENT_DIR)
	@cat $(GOPATH)/bin/klient | gzip -9 > $(KLIENT_DIR)/klient.gz

.PHONY: configure run
