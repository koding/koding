// Package utils provides helper functions for other subpackages
package utils

import (
	"errors"
	"io/ioutil"
	"os"
	"path/filepath"
)

var (
	// ErrPathNotSet states that given path to file loader is empty
	ErrPathNotSet = errors.New("path is not set")

	// ErrFileNotFound states that given file is not exists
	ErrFileNotFound = errors.New("file not found")
)

// ReadFile reads the given file, first it tries to read with relative path,
// then tries with exact given path
func ReadFile(path string) ([]byte, error) {
	filePath, err := getExactPath(path)
	if err != nil {
		return nil, err
	}

	return ioutil.ReadFile(filePath)
}

func getExactPath(path string) (string, error) {
	if path == "" {
		return "", ErrPathNotSet
	}

	pwd, err := os.Getwd()
	if err != nil {
		return "", err
	}

	configPath := filepath.Join(pwd, path)

	// check if file with combined path is exists(relative path)
	if _, err := os.Stat(configPath); !os.IsNotExist(err) {
		return configPath, nil
	}

	// check if file is exists it self
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		return path, nil
	}

	return "", ErrFileNotFound
}
