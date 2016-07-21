BINARIES := $(shell find src/ -maxdepth 1 -type d -name 'artif-*' -exec sh -c 'echo $(basename {})' \;)
BINLIST := $(subst src/,,$(BINARIES))
#BINARIES = $(sort $(dir $(wildcard src/artif-*/)))
#BINARIES = artif-list-repos artif-get-repo artif-get-license artif-list-users artif-get-user artif-list-groups artif-get-group artif-list-permission-targets artif-get-permission-target artif-create-user artif-delete-user artif-deploy-artifact

ifeq ($(TRAVIS_BUILD_DIR),)
	GOPATH := $(GOPATH)
else
	GOPATH := $(GOPATH):$(TRAVIS_BUILD_DIR)
endif
all: clean test artifactory $(BINLIST)

test:
	@go test artifactory.v401 #-test.v

artifactory:
	@go get ./... 
	@go install artifactory.v401

$(BINLIST):
	@echo $@
	@go install $@

clean:
	@rm -rf bin/ pkg/

.PHONY: all clean test artifactory $(BINLIST)
