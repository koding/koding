package logger

import (
	"koding/tools/config"
)


// Get logging level from config file for the given worker name & find the
// appropriate logging.Level
func GetLoggingLevelFromConfig(name, profile string) Level {
	c := config.MustConfig(profile)
	var logLevelString, ok = c.LogLevel[name]
	if !ok {
		return DefaultLoggingLevel
	}

	currentLogLevel, ok = nameToLevelMapping[logLevelString]
	if !ok {
		return DefaultLoggingLevel
	}

	return currentLogLevel
}
