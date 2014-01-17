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

var defaultLoggingLevel = logging.WARNING

// Get logging level from config file & find the appropriate logging.Level
func getLoggingLevelFromConfig(name string) logging.Level {
	var logLevelString, ok = config.Current.LogLevel[name]
	if !ok {
		return defaultLoggingLevel
	}

	loggingLevel, ok = nameToLevelMapping[logLevelString]
	if !ok {
		return defaultLoggingLevel
	}

	return loggingLevel
}
