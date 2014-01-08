package logger

import (
	"github.com/op/go-logging"
	"koding/tools/config"
)

var loggingLevel logging.Level

var nameToLevelMapping = map[string]logging.Level{
	"debug":   logging.DEBUG,
	"warning": logging.WARNING,
	"error":   logging.ERROR,
}

// Get logging level from config file and find the appropriate logging.Level
// from string.
func init() {
	var exists bool
	var logLevelString = config.Current.Neo4j.LogLevel

	loggingLevel, exists = nameToLevelMapping[logLevelString]
	if !exists {
		loggingLevel = logging.DEBUG
	}
}
