ALL_GO_FILES = $(wildcard *.go)
ALL_FILES = $(patsubst %.go,%,$(ALL_GO_FILES))

all:
	@$(foreach file,$(ALL_GO_FILES),go build $(file);)
clean:
	@$(foreach file,$(ALL_FILES),rm -f $(file);)
format:
	@gofmt -s -w *.go
