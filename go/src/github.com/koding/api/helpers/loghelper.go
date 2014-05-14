package helpers

import (
	"github.com/koding/logging"
	"github.com/koding/worker/helpers"
)

var log logging.Logger

func MustInitLogger(name string, debug bool) logging.Logger {
	log = helpers.CreateLogger(name, debug)

	return log
}

func MustGetLogger() logging.Logger {
	if log == nil {
		panic("Logger is not initialized. You should call \"MustInitLogger(name string, debug bool)\" first")
	}

	return log
}
