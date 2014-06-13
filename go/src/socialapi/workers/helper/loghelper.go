package helper

import (
	"fmt"
	"os"
	"time"

	"github.com/koding/logging"
)

var log logging.Logger

type Formatter struct{}

func (f *Formatter) Format(rec *logging.Record) string {
	return fmt.Sprintf("%-24s %-8s [%-15s] %s",
		time.Now().UTC().Format("2006-01-02T15:04:05.999Z"),
		logging.LevelNames[rec.Level],
		rec.LoggerName,
		fmt.Sprintf(rec.Format, rec.Args...),
	)
}

func CreateLogger(name string, debug bool) logging.Logger {
	log = logging.NewLogger(name)
	logHandler := logging.NewWriterHandler(os.Stderr)
	logHandler.Formatter = &Formatter{}
	logHandler.Colorize = true
	log.SetHandler(logHandler)

	if debug {
		log.SetLevel(logging.DEBUG)
		logHandler.SetLevel(logging.DEBUG)
	}

	return log
}

func MustGetLogger() logging.Logger {
	if log == nil {
		panic("Logger is not initialized. You should call \"MustInitLogger(name string, debug bool)\" first")
	}

	return log
}
