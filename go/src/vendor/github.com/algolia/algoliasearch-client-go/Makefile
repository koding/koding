PROJECT=algoliasearch
COVERAGE_FILE=coverage.out

install:
	go install ./$(PROJECT)

test: test-unit

test-unit:
	go test -v ./$(PROJECT)

coverage:
	go list -f '{{if gt (len .TestGoFiles) 0}}"go test -covermode count -coverprofile {{.Name}}.coverprofile -coverpkg ./... {{.ImportPath}}"{{end}}' ./... | xargs -I {} bash -c {}
	gocovmerge `ls *.coverprofile` > $(COVERAGE_FILE)
	go tool cover -html=$(COVERAGE_FILE)

.PHONY: install test clean
