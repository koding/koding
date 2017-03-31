NO_COLOR=\033[0m
OK_COLOR=\033[0;32m

all: build

test:
	@echo "$(OK_COLOR)==> Testing all packages $(NO_COLOR)"
	@`which go` test -race  ./...

build:
	@echo "$(OK_COLOR)==> Building all packages $(NO_COLOR)"
	@`which go` build -v -ldflags "-X koding/klient/config.Version=0.1.330 -X koding/klient/config.Environment=development"

.PHONY: all build test
