package config

import (
	"os"
	"path/filepath"
)

const (
	logFilePath        = "/var/log"
	upstartlogFilePath = "/var/log/upstart"
)

// returnExistingPath checks the given paths and returns the first
// that exists. If none exist, empty is returned.
func returnExistingPath(paths []string) string {
	for _, p := range paths {
		if _, err := os.Stat(p); !os.IsNotExist(err) {
			return p
		}
	}

	return ""
}

func GetKlientLogPath() string {
	return returnExistingPath([]string{
		filepath.Join(logFilePath, klientLogName),
		filepath.Join(upstartlogFilePath, klientLogName),
	})
}

func GetKdLogPath() string {
	return returnExistingPath([]string{
		filepath.Join(logFilePath, kdLogName),
		filepath.Join(upstartlogFilePath, kdLogName),
	})
}
