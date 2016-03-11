# build steps including dependencies.
# You do not have to use these but they are the canonical steps.
# You can pass some flags in:
#   GOBUILDFLAGS controls the go build/install step
#   GOTESTFLAGS controls the go test step

all: test install

.PHONY: install test godep

# Build
VERSION = '$(shell git describe --tags --always --dirty)'
GOVERSION = '$(shell go version)'
BUILDTIME = '$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")'
install: godep
	touch cmd/sneaker/version.go
	${GOPATH}/bin/godep go install $(GOBUILDFLAGS) -ldflags "-X main.version $(VERSION) -X main.goVersion $(GOVERSION) -X main.buildTime $(BUILDTIME)" ./...

# run tests
test: godep
	${GOPATH}/bin/godep go test $(GOTESTFLAGS) ./...

vendor: godep
	rm -rf Godep
	godep save ./...

# Bootstrap godep
godep: ${GOPATH}/bin/godep
${GOPATH}/bin/godep:
	go get -u github.com/tools/godep
	go install github.com/tools/godep
