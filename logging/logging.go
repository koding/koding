package logging

import (
	"io"

	"github.com/koding/logging"
)

// Logger is a thin wrapper around koding/logging's Logger interface,
// implementing GoVet compliant log functions with the f character
// appended. Eg, Infoff instead of Info.
type Logger interface {
	// Implement the rest of the koding/logging.Logger
	logging.Logger

	// Fatalf is equivalent to l.Criticalf followed by a call to os.Exit(1).
	Fatalf(format string, args ...interface{})

	// Panicf is equivalent to l.Criticalf followed by a call to panic().
	Panicf(format string, args ...interface{})

	// Criticalf logs a message using CRITICAL as log level.
	Criticalf(format string, args ...interface{})

	// Errorf logs a message using ERROR as log level.
	Errorf(format string, args ...interface{})

	// Warningf logs a message using WARNING as log level.
	Warningf(format string, args ...interface{})

	// Noticef logs a message using NOTICE as log level.
	Noticef(format string, args ...interface{})

	// Infof logs a message using INFO as log level.
	Infof(format string, args ...interface{})

	// Debugf logs a message using DEBUG as log level.
	Debugf(format string, args ...interface{})
}

// logger implements the Logger interface, embedding the koding/logging.Logger struct
// for all meaningful functionality.
type logger struct {
	logging.Logger
}

// NewLogger creates a new Logger, with the koding/logging.Logger embedded.
func NewLogger(name string) Logger {
	return &logger{
		Logger: logging.NewLogger(name),
	}
}

// NewWriterHandler simply creates a koding/logging.WriterHandler and returns it.
// This func exists to allow the caller to create a Logger and a WriterHandler with
// a single logging namespace, not needing to access the koding/logging namespace.
func NewWriterHandler(w io.Writer) *logging.WriterHandler {
	return logging.NewWriterHandler(w)
}

func (l *logger) Fatalf(f string, args ...interface{}) {
	l.Fatal(f, args...)
}

func (l *logger) Panicf(f string, args ...interface{}) {
	l.Panic(f, args...)
}

func (l *logger) Criticalf(f string, args ...interface{}) {
	l.Critical(f, args...)
}

func (l *logger) Errorf(f string, args ...interface{}) {
	l.Error(f, args...)
}

func (l *logger) Warningf(f string, args ...interface{}) {
	l.Warning(f, args...)
}

func (l *logger) Noticef(f string, args ...interface{}) {
	l.Notice(f, args...)
}

func (l *logger) Infof(f string, args ...interface{}) {
	l.Info(f, args...)
}

func (l *logger) Debugf(f string, args ...interface{}) {
	l.Debug(f, args...)
}
