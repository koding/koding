# fusetest

This package is used to run common file system operations (mkdir, rm, mv etc) on
an already mounted folder.

To test if local changes are reflected on remote it initializes SSH connection
to remote.

It uses the test helper package GoConvey to check for assertions.

## Getting starting

```
go run $GOPATH/koding/fuseklient/cmd/fusetest/main.go -test.v=true <machine name>
```

To run tests with mount settings, such as prefetch-all, use:

```
go run $GOPATH/koding/fuseklient/cmd/fusetest/main.go -test.v=true -mount-setting-tests=true <machine name>
```

To run tests with internet reconnect testing (on OSX), use:

```
go run $GOPATH/koding/fuseklient/cmd/fusetest/main.go -test.v=true -reconnect-depth=1 <machine name>
```

Depth uint values will pause for greater times. Current supported values:

`1` - Disconnect for 30s, 10s recover.
`2` - Disconnect for 8m, 2m recover.
