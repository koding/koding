NO_COLOR=\033[0m
OK_COLOR=\033[0;32m

all: build

test:
	@echo "$(OK_COLOR)==> Testing all packages $(NO_COLOR)"
	@`which go` test -race  ./...

build:
	@echo "$(OK_COLOR)==> Building all packages $(NO_COLOR)"
	@`which go` build -v -ldflags "-X koding/klient/protocol.Version 0.0.1 -X koding/klient/protocol.Environment devbuild"

.PHONY: all build test

