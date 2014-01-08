package logger

import (
	"github.com/op/go-logging"
	stdlog "log"
	"os"
)

type GoLogger struct {
	log *logging.Logger
}

func NewGoLog(name string) *GoLogger {
	logging.SetFormatter(logging.MustStringFormatter("[%{level:.8s}] - %{message}"))

	// Send log to stdout
	var logBackend = logging.NewLogBackend(os.Stderr, "", stdlog.LstdFlags|stdlog.Lshortfile)
	logBackend.Color = true

	// Send log to syslog
	var syslogBackend, err = logging.NewSyslogBackend("")
	if err != nil {
		panic(err)
	}

	logging.SetBackend(logBackend, syslogBackend)

	// Set logging level based on value in config.
	logging.SetLevel(loggingLevel, name)

	var goLog = &GoLogger{logging.MustGetLogger(name)}

	return goLog
}

func (g *GoLogger) Panic(format string, args ...interface{}) {
	g.log.Panicf(format, args...)
}

func (g *GoLogger) Critical(format string, args ...interface{}) {
	g.log.Critical(format, args...)
}

func (g *GoLogger) Error(format string, args ...interface{}) {
	g.log.Error(format, args...)
}

func (g *GoLogger) Warning(format string, args ...interface{}) {
	g.log.Warning(format, args...)
}

func (g *GoLogger) Notice(format string, args ...interface{}) {
	g.log.Notice(format, args...)
}

func (g *GoLogger) Info(format string, args ...interface{}) {
	g.log.Info(format, args...)
}

func (g *GoLogger) Debug(format string, args ...interface{}) {
	g.log.Debug(format, args...)
}

func (g *GoLogger) RecoverAndLog(format string, args ...interface{}) {
	if err := recover(); err != nil {
		g.Critical(format, args)
		g.Critical("Panicked %v", err)
	}
}
