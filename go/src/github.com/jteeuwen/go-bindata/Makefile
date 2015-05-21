all: regen check

regen:
	go install ./...
	make -C testdata regen

.PHONY: check
check: errcheck go-nyet
	errcheck testdata/out/compress-memcopy.go
	errcheck testdata/out/compress-nomemcopy.go
	errcheck testdata/out/debug.go
	errcheck testdata/out/nocompress-memcopy.go
	errcheck testdata/out/nocompress-nomemcopy.go
	go-nyet testdata/out/compress-memcopy.go
	go-nyet testdata/out/compress-nomemcopy.go
	go-nyet testdata/out/debug.go
	go-nyet testdata/out/nocompress-memcopy.go
	go-nyet testdata/out/nocompress-nomemcopy.go

errcheck:
	go get github.com/kisielk/errcheck

go-nyet:
	go get github.com/barakmich/go-nyet
