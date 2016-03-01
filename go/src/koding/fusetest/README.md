# fusetest

This package is used to run common file system operations (mkdir, rm, mv etc) on
a mounted folder.

It uses the test helper package GoConvey to check for assertions.

## Getting starting

    go run cmd/fusetest/main.go <mount folder> -test.v=true
