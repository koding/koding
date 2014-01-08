package logger

import (
	"github.com/op/go-logging"
	"koding/tools/config"
)

// Stores current logging level.
var loggingLevel logging.Level

// Mappings of strings in config file to internal types.
var nameToLevelMapping = map[string]logging.Level{
	"debug":   logging.DEBUG,
	"warning": logging.WARNING,
	"error":   logging.ERROR,
}

// Get logging level from config file & find the appropriate logging.Level
func init() {
	var exists bool
	var logLevelString = config.Current.GoLogLevel

	loggingLevel, exists = nameToLevelMapping[logLevelString]
	if !exists {
		loggingLevel = logging.DEBUG
	}
}
