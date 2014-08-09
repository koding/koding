package logger

import (
	"fmt"
	stdlog "log"
	"os"
	"runtime"
	"runtime/debug"

	"github.com/sent-hil/go-logging"
)

var modules []string

func init() {
	modules = []string{}
}

// Default Log implementation.
type GoLogger struct {
	log  *logging.Logger
	name string
}

func NewGoLog(name string) *GoLogger {
	logging.SetFormatter(logging.MustStringFormatter("%{module} [%{level:.8s}] - %{message}"))

	// Send log to stdout
	var logBackend = logging.NewLogBackend(os.Stderr, "", stdlog.LstdFlags|stdlog.Lshortfile)
	logBackend.Color = true

	// Send log to syslog
	// var syslogBackend, err = logging.NewSyslogBackend("", syslog.LOG_DEBUG|syslog.LOG_LOCAL0)
	// if err != nil {
	// 	panic(err)
	// }

	logging.SetBackend(logBackend)

	// go-logging calls Reset() each time it is imported. So if this
	// pkg is imported in a library and then in a worker, the library
	// defaults back to DEBUG logging level. This fixes that by
	// re-setting the log level for already set modules.
	modules = append(modules, name)
	for _, mod := range modules {
		logging.SetLevel(gologgingLevel[DefaultLoggingLevel], mod)
	}

	var goLog = &GoLogger{
		log:  logging.MustGetLogger(name),
		name: name,
	}

	return goLog
}

// Mappings of internal Level to go-logging level
var gologgingLevel = map[Level]logging.Level{
	CRITICAL: logging.CRITICAL,
	DEBUG:    logging.DEBUG,
	ERROR:    logging.ERROR,
	INFO:     logging.INFO,
	NOTICE:   logging.NOTICE,
	WARNING:  logging.WARNING,
}

func (g *GoLogger) SetLevel(level Level) {
	var l, ok = gologgingLevel[level]
	if !ok {
		g.log.Error("SetLevel argument is false: %s", level)
		l = gologgingLevel[DefaultLoggingLevel]
	}

	logging.SetLevel(l, g.name)
}

func (g *GoLogger) Fatal(args ...interface{}) {
	g.log.Fatal(args...)
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

func (g *GoLogger) Name() string {
	return g.log.Module
}

//----------------------------------------------------------
// Originally from koding/tools/log
//----------------------------------------------------------

func (g *GoLogger) RecoverAndLog() {
	if err := recover(); err != nil {
		debug.PrintStack()
		g.Critical("Panicked %v", err)
	}
}

func (g *GoLogger) LogError(err interface{}, stackOffset int, additionalData ...interface{}) {
	data := make([]interface{}, 0)
	data = append(data, fmt.Sprintln(err))
	for i := 1 + stackOffset; ; i++ {
		pc, file, line, ok := runtime.Caller(i)
		if !ok {
			break
		}
		name := "<unknown>"
		if fn := runtime.FuncForPC(pc); fn != nil {
			name = fn.Name()
		}
		data = append(data, fmt.Sprintf("at %s (%s:%d)\n", name, file, line))
	}
	data = append(data, additionalData...)
	g.Error("%v", data)
}
