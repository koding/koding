package config

import "path/filepath"

const logFilePath = "/Library/Logs"

func GetKlientLogPath() string {
	return filepath.Join(logFilePath, klientLogName)
}

func GetKdLogPath() string {
	return filepath.Join(logFilePath, kdLogName)
}
