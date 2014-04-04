# MAKEFLAGS += -j
NO_COLOR=\033[0m
OK_COLOR=\033[0;32m
PWD=`pwd`
GODIR=$(PWD)/../../../go
GOBINDIR=$(GODIR)/bin
CONFIG=./config/vagrant.toml
GO=

develop: apidev topicfeeddev realtimedev followingfeeddev

apidev:
	@echo "$(OK_COLOR)==> Running API Worker $(NO_COLOR)"
	$(GOBINDIR)/rerun socialapi/workers/api -c $(CONFIG) -d
topicfeeddev:
	@echo "$(OK_COLOR)==> Running Topic Feed Worker $(NO_COLOR)"
	$(GOBINDIR)/rerun socialapi/workers/topicfeed -c $(CONFIG) -d
realtimedev:
	@echo "$(OK_COLOR)==> Running Realtime Worker $(NO_COLOR)"
	$(GOBINDIR)/rerun socialapi/workers/realtime -c $(CONFIG)  -d
followingfeeddev:
	@echo "$(OK_COLOR)==> Running Following Feed Worker $(NO_COLOR)"
	$(GOBINDIR)/rerun socialapi/workers/followingfeed -c $(CONFIG) -d

PACKAGES = \
	socialapi/workers/followingfeed \
	socialapi/workers/realtime \
	socialapi/workers/topicfeed

default: all

configure: installall installrerun
	@echo "$(OK_COLOR)==> Configuration is done $(NO_COLOR)"

installrerun:
	@go get github.com/skelterjohn/rerun
	@go build github.com/skelterjohn/rerun
	@go install github.com/skelterjohn/rerun

installall:
	@for package in $(PACKAGES); do (go build $$package); done
	@for package in $(PACKAGES); do (go install $$package); done
	@echo "$(OK_COLOR)==> Installed all packages $(NO_COLOR)"

test:
	@for package in $(PACKAGES); \
	do \
		(echo "$(OK_COLOR)==> Running go test for $$package $(NO_COLOR)"); \
		go test -v $$package; \
	done;

doc:
	@for package in $(PACKAGES); \
	do \
		(echo "$(OK_COLOR)==> Running godoc for $$package $(NO_COLOR)"); \
		godoc $$package | less; \
	done;

vet:
	@`which go` tool vet -all=true .

.PHONY: all
