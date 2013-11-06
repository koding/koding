## Golang logging library

Package logging implements a logging infrastructure for Go. It supports
different logging backends like syslog, file and memory. Multiple backends
can be utilized with different log levels per backend and logger.

## Installing

### Using *go get*

    $ go get github.com/op/go-logging

After this command *go-logging* is ready to use. Its source will be in:

    $GOROOT/src/pkg/github.com/op/go-logging

You can use `go get -u -a` to update all installed packages.

## Example

```go
package main

import "github.com/op/go-logging"

var log = logging.MustGetLogger("package.example")

func main() {
	var format = logging.MustStringFormatter("%{level} %{message}")
	logging.SetFormatter(format)
	logging.SetLevel(logging.INFO, "package.example")

	log.Debug("hello %s", "golang")
	log.Info("hello %s", "golang")
}
```

## Documentation

Examples are found in `examples/`. For docs, see http://godoc.org/github.com/op/go-logging or run:

    $ go doc github.com/op/go-logging
