## Golang logging library

[![Build Status](https://travis-ci.org/op/go-logging.png)](https://travis-ci.org/op/go-logging)

Package logging implements a logging infrastructure for Go. It supports
different logging backends like syslog, file and memory. Multiple backends
can be utilized with different log levels per backend and logger.

## Forked

This is a forked version. There are couple minor changes here which I'll
eventually open a MR for.

## Installing

### Using *go get*

    $ go get github.com/op/go-logging

After this command *go-logging* is ready to use. Its source will be in:

    $GOROOT/src/pkg/github.com/op/go-logging

You can use `go get -u -a` to update all installed packages.

## Example

You can find a more detailed example at the end.

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

For docs, see http://godoc.org/github.com/op/go-logging or run:

    $ go doc github.com/op/go-logging

## Full example

```go
package main

import (
	stdlog "log"
	"log/syslog"
	"os"

	"github.com/op/go-logging"
)

var log = logging.MustGetLogger("test")

type Password string

func (p Password) Redacted() interface{} {
	return logging.Redact(string(p))
}

func main() {
	// Customize the output format
	logging.SetFormatter(logging.MustStringFormatter("▶ %{level:.1s} 0x%{id:x} %{message}"))

	// Setup one stdout and one syslog backend.
	logBackend := logging.NewLogBackend(os.Stderr, "", stdlog.LstdFlags|stdlog.Lshortfile)
	logBackend.Color = true

	syslogBackend, err := logging.NewSyslogBackend("", syslog.LOG_DEBUG|syslog.LOG_LOCAL0)
	if err != nil {
		log.Fatal(err)
	}

	// Combine them both into one logging backend.
	logging.SetBackend(logBackend, syslogBackend)

	// Run one with debug setup for "test" and one with error.
	for _, level := range []logging.Level{logging.DEBUG, logging.ERROR} {
		logging.SetLevel(level, "test")

		log.Critical("crit")
		log.Error("err")
		log.Warning("warning")
		log.Notice("notice")
		log.Info("info")
		log.Debug("debug %s", Password("secret"))
	}
}
```
