package logger

import (
	"github.com/op/go-logging"
	"koding/tools/config"
	stdlog "log"
	"os"
)

var loggingLevel logging.Level

var nameToLevelMapping = map[string]logging.Level{
	"debug":   logging.DEBUG,
	"warning": logging.WARNING,
	"error":   logging.ERROR,
}

// Get logging level from config file and find the appropriate logging.Level
// from string.
func init() {
	var exists bool
	var logLevelString = config.Current.Neo4j.LogLevel

	loggingLevel, exists = nameToLevelMapping[logLevelString]
	if !exists {
		loggingLevel = logging.DEBUG
	}
}

func New(name string) *logging.Logger {
	logging.SetFormatter(logging.MustStringFormatter("[%{level:.8s}] - %{message}"))

	var logBackend = logging.NewLogBackend(os.Stderr, "", stdlog.LstdFlags|stdlog.Lshortfile)
	logBackend.Color = true

	var syslogBackend, err = logging.NewSyslogBackend("")
	if err != nil {
		panic(err)
	}

	logging.SetBackend(logBackend, syslogBackend)

	// Set logging level based on value in config.
	logging.SetLevel(loggingLevel, name)

	return logging.MustGetLogger(name)
}
