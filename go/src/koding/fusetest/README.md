# fusetest

This package is used to run common file system operations (mkdir, rm, mv etc) on
an already mounted folder.

To test if local changes are reflected on remote it initializes SSH connection
to remote.

It uses the test helper package GoConvey to check for assertions.

## Getting starting

To run just fuseop tests on your current mount, use:

```
go run $GOPATH/koding/fuseklient/cmd/fusetest/main.go -test.v=true <machine name>
```

To run *all* tests, use the `-all=true` flag. To run all tests except the
especially slow ones like internet reconnecting use the flag
`-almost-all`. Example:

```
go run $GOPATH/koding/fuseklient/cmd/fusetest/main.go -test.v=true -all=true <machine name>
# and
go run $GOPATH/koding/fuseklient/cmd/fusetest/main.go -test.v=true -almost-all=true <machine name>
```

To run tests that mount and unmount with various settings, such as
prefetch-all, no-prefetch, etc, use:

```
go run $GOPATH/koding/fuseklient/cmd/fusetest/main.go -test.v=true -mount-settings=true <machine name>
```

To run tests with internet reconnect testing (on OSX), use:

```
go run $GOPATH/koding/fuseklient/cmd/fusetest/main.go -test.v=true -reconnect-depth=1 <machine name>
```

Depth uint values will pause for greater times. Current supported values:

`1` - Disconnect for 30s, 10s recover.
`2` - Disconnect for 8m, 2m recover.

To run tests with general kd tests, such as kd list working as expected, use:

```
go run $GOPATH/koding/fuseklient/cmd/fusetest/main.go -test.v=true -kd=true <machine name>
```
