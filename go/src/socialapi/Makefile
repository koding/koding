MAKEFLAGS += -j
NO_COLOR=\033[0m
OK_COLOR=\033[0;32m

develop: api topicfeed realtime followingfeed

api:
	@echo "$(OK_COLOR)==> Running API Worker $(NO_COLOR)"
	../../../go/bin/rerun socialapi/workers/api -c ./config/vagrant.toml -d
topicfeed:
	@echo "$(OK_COLOR)==> Running Topic Feed Worker $(NO_COLOR)"
	../../../go/bin/rerun socialapi/workers/topicfeed -c ./config/vagrant.toml -d
realtime:
	@echo "$(OK_COLOR)==> Running Realtime Worker $(NO_COLOR)"
	../../../go/bin/rerun socialapi/workers/realtime -c ./config/vagrant.toml  -d
followingfeed:
	@echo "$(OK_COLOR)==> Running Following Feed Worker $(NO_COLOR)"
	../../../go/bin/rerun socialapi/workers/followingfeed -c ./config/vagrant.toml -d

SUBDIRS = \
	socialapi/workers/followingfeed \
	socialapi/workers/realtime \
	socialapi/workers/topicfeed

default: all

build:
	@for dir in $(SUBDIRS); do (go build $$dir); done

test:
	@for dir in $(SUBDIRS); \
	do \
		(echo "$(OK_COLOR)==> Running go test for $$dir $(NO_COLOR)"); \
		`which go` test -v $$dir; \
	done;

doc:
	@for dir in $(SUBDIRS); \
	do \
		(echo "$(OK_COLOR)==> Running godoc for $$dir $(NO_COLOR)"); \
		`which godoc` $$dir | less; \
	done;

vet:
	@`which go` tool vet -all=true .

.PHONY: all
