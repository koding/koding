DEPS = $(go list -f '{{range .TestImports}}{{.}} {{end}}' ./...)

all: deps build

deps:
	go get -d -v ./...
	echo $(DEPS) | xargs -n1 go get -d

build:
	@mkdir -p bin/
	go build -o bin/atlas-go ./v1

test: deps
	go list ./... | xargs -n1 go test -timeout=3s

.PHONY: all deps build test
