package multiconfig

import (
	"encoding/json"
	"errors"
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/BurntSushi/toml"
)

var (
	// ErrPathNotSet states that given path to file loader is empty
	ErrPathNotSet = errors.New("config path is not set")

	// ErrFileNotFound states that given file is not exists
	ErrFileNotFound = errors.New("config file not found")
)

// TOMLLoader satisifies the loader interface. It loads the configuration from
// the given toml file.
type TOMLLoader struct {
	Path string
}

// Load loads the source into the config defined by struct s
func (t *TOMLLoader) Load(s interface{}) error {
	filePath, err := getConfigPath(t.Path)
	if err != nil {
		return err
	}

	if _, err := toml.DecodeFile(filePath, s); err != nil {
		return err
	}

	return nil
}

// JSONLoader satisifies the loader interface. It loads the configuration from
// the given json file.
type JSONLoader struct {
	Path string
}

// Load loads the source into the config defined by struct s
func (j *JSONLoader) Load(s interface{}) error {
	filePath, err := getConfigPath(j.Path)
	if err != nil {
		return err
	}

	file, err := ioutil.ReadFile(filePath)
	if err != nil {
		return err
	}

	return json.Unmarshal(file, s)
}

func getConfigPath(path string) (string, error) {
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
