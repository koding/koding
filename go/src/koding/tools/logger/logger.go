package logger

import (
	logging "github.com/op/go-logging"
	stdlog "log"
	"os"
)

func init() {
	// format can be added to the config
	logging.SetFormatter(logging.MustStringFormatter("%{level:-8s} ▶ %{message}"))
	stderrBackend := logging.NewLogBackend(os.Stderr, "", stdlog.LstdFlags|stdlog.Lshortfile)
	stderrBackend.Color = true
	syslogBackend, _ := logging.NewSyslogBackend("")
	logging.SetBackend(stderrBackend, syslogBackend)
}

func CreateLogger(module string, level string) *logging.Logger {
	l, err := logging.LogLevel(level)
	if err != nil {
		panic(err)
	}
	logging.SetLevel(l, module)
	logger := logging.MustGetLogger(module)
	logger.Module = module
	return logger
}
