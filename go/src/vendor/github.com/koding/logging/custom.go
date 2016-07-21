package logging

import (
	"fmt"
	"os"
	"strings"
)

type CustomFormatter struct{}

func (f *CustomFormatter) Format(rec *Record) string {
	paths := strings.Split(rec.Filename, string(os.PathSeparator))
	// does even anyone uses root folder as their gopath?
	filePath := strings.Join(paths[len(paths)-2:], string(os.PathSeparator))

	return fmt.Sprintf("%-24s %-8s [%-15s][PID:%d][%s:%d] %s",
		rec.Time.UTC().Format("2006-01-02T15:04:05.999Z"),
		LevelNames[rec.Level],
		rec.LoggerName,
		rec.ProcessID,
		filePath,
		rec.Line,
		fmt.Sprintf(rec.Format, rec.Args...),
	)
}

func NewCustom(name string, debug bool) Logger {
	log := NewLogger(name)
	logHandler := NewWriterHandler(os.Stderr)
	logHandler.Formatter = &CustomFormatter{}
	logHandler.Colorize = true
	log.SetHandler(logHandler)

	if debug {
		log.SetLevel(DEBUG)
		logHandler.SetLevel(DEBUG)
	}

	return log
}
