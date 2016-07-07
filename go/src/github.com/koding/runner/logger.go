package runner

import "github.com/koding/logging"

var log logging.Logger

func CreateLogger(name string, debug bool) logging.Logger {
	log = logging.NewCustom(name, debug)
	return log
}

func MustGetLogger() logging.Logger {
	if log == nil {
		panic("Logger is not initialized. You should call \"MustInitLogger(name string, debug bool)\" first")
	}

	return log
}
