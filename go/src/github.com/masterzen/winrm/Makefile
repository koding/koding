NO_COLOR=\033[0m
OK_COLOR=\033[32;01m
ERROR_COLOR=\033[31;01m
WARN_COLOR=\033[33;01m
DEPS = $(go list -f '{{range .TestImports}}{{.}} {{end}}' ./...)

all: deps
	@mkdir -p bin/
	@echo "$(OK_COLOR)==> Building$(NO_COLOR)"
	@go build -o $(GOPATH)/bin/winrm github.com/masterzen/winrm

deps:
	@echo "$(OK_COLOR)==> Installing dependencies$(NO_COLOR)"
	@go get -d -v ./...
	@echo $(DEPS) | xargs -n1 go get -d

updatedeps:
	@echo "$(OK_COLOR)==> Updating all dependencies$(NO_COLOR)"
	@go get -d -v -u ./...
	@echo $(DEPS) | xargs -n1 go get -d -u -t

clean:
	@rm -rf bin/ pkg/ src/

format:
	go fmt ./...

ci: deps
	@echo "$(OK_COLOR)==> Testing Packer with Coveralls...$(NO_COLOR)"
	"$(CURDIR)/scripts/test.sh"

test: deps
	@echo "$(OK_COLOR)==> Testing Packer...$(NO_COLOR)"
	go test ./...

.PHONY: all clean deps format test updatedeps
