SRC=$(wildcard algoliasearch/*.go)
PROJECT=algoliasearch

.PHONY: test algoliasearch

algoliasearch: ${SRC}
	go build test/test_readme.go

test: ${SRC}
	go test ${SRC}

clean:
	${RM} ${PROJECT}
