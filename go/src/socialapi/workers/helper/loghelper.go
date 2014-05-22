package helper

// TODO use loghelper under koding/worker package instead of this

import (
	"fmt"
	"os"
	"time"

	"github.com/koding/logging"
)

type Formatter struct{}

func (f *Formatter) Format(rec *logging.Record) string {
	return fmt.Sprintf("%s %-8s [%s] %s",
		time.Now().UTC().Format("2006-01-02T15:04:05.999Z"),
		logging.LevelNames[rec.Level],
		rec.LoggerName,
		fmt.Sprintf(rec.Format, rec.Args...),
	)
}

func CreateLogger(name string, debug bool) logging.Logger {
	log := logging.NewLogger(name)
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
