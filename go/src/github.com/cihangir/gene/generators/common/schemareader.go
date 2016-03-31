package common

import (
	"encoding/json"
	"errors"
	"path/filepath"

	"github.com/BurntSushi/toml"
	"github.com/cihangir/gene/helpers"
	"github.com/cihangir/schema"
	"gopkg.in/yaml.v2"
)

// NewFromFile reads the given file and creates a new module out of it
func Read(path string) (*schema.Schema, error) {
	fileContent, err := helpers.ReadFile(path)
	if err != nil {
		return nil, err
	}

	return unmarshall(path, fileContent)
}

func unmarshall(path string, fileContent []byte) (*schema.Schema, error) {
	s := &schema.Schema{}

	// Choose what what kind of file is passed
	switch filepath.Ext(path) {
	case ".toml":
		if err := toml.Unmarshal(fileContent, s); err != nil {
			return nil, err
		}
	case ".json":
		if err := json.Unmarshal(fileContent, s); err != nil {
			return nil, err
		}
	case ".yaml", ".yml":
		if err := yaml.Unmarshal(fileContent, s); err != nil {
			return nil, err
		}
	default:
		return nil, errors.New("Unmarshal not implemented")
	}

	return s, nil
}
