package runner

import (
	"fmt"
	"os"
	"strings"

	"github.com/koding/logging"
)

var log logging.Logger

type Formatter struct{}

func (f *Formatter) Format(rec *logging.Record) string {
	paths := strings.Split(rec.Filename, string(os.PathSeparator))
	// does even anyone uses root folder as their gopath?
	filePath := strings.Join(paths[len(paths)-2:], string(os.PathSeparator))

	return fmt.Sprintf("%-24s %-8s [%-15s][PID:%d][%s:%d] %s",
		rec.Time.UTC().Format("2006-01-02T15:04:05.999Z"),
		logging.LevelNames[rec.Level],
		rec.LoggerName,
		rec.ProcessID,
		filePath,
		rec.Line,
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
