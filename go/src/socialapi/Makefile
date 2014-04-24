# MAKEFLAGS += -j
NO_COLOR=\033[0m
OK_COLOR=\033[0;32m
CWD=`pwd`
GODIR=$(CWD)/../../../go
GOBINDIR=$(GODIR)/bin
CONFIG=./config/vagrant.toml

MAJOR=0
MINOR=1
# export MAJOR
# export MINOR

develop: apidev topicfeeddev realtimedev followingfeeddev populartopicdev

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

PACKAGES = \
	socialapi/workers/api \
	socialapi/workers/topicfeed \
	socialapi/workers/realtime \
	socialapi/workers/followingfeed \
	socialapi/workers/populartopic

default: all

createdb:
	@go run ./scripts/createdb.go -c ./config/vagrant.toml  -d

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

testapi:
	(echo "$(OK_COLOR)==> Running go api tests $(NO_COLOR)"); \
	@go run ./tests/*.go

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
	topicfeed

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

.PHONY: all
