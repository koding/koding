package logger

import (
	"github.com/sent-hil/go-logging"
	"koding/tools/config"
)

// Stores current logging level.
var loggingLevel logging.Level

// Mappings of strings in config file to internal types.
var nameToLevelMapping = map[string]logging.Level{
	"critical": logging.CRITICAL,
	"debug":    logging.DEBUG,
	"error":    logging.ERROR,
	"info":     logging.INFO,
	"notice":   logging.NOTICE,
	"warning":  logging.WARNING,
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
