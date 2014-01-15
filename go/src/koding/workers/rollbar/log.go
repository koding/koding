package main

import (
	"github.com/op/go-logging"
	stdlog "log"
	"os"
)

var log = logging.MustGetLogger("rollbar")

func init() {
	logging.SetFormatter(logging.MustStringFormatter("%{message}"))

	var logBackend = logging.NewLogBackend(os.Stderr, "", stdlog.LstdFlags|stdlog.Lshortfile)
	logBackend.Color = true

	logging.SetBackend(logBackend)
}
