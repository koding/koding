# fusetest

This package is used to run common file system operations (mkdir, rm, mv etc) on
an already mounted folder.

To test if local changes are reflected on remote it initializes SSH connection
to remote.

It uses the test helper package GoConvey to check for assertions.

## Getting starting

    go run $GOPATH/koding/fuseklient/cmd/fusetest/main.go <machine name> -test.v=true`
