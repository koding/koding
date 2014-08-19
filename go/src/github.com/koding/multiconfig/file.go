package multiconfig

import (
	"encoding/json"
	"errors"
	"io/ioutil"

	"github.com/BurntSushi/toml"
)

var (
	errPathNotSet = errors.New("config path is not set")
)

// TOMLLoader satisifies the loader interface. It loads the configuration from
// the given toml file.
type TOMLLoader struct {
	Path string
}

func (t *TOMLLoader) Load(s interface{}) error {
	if t.Path == "" {
		return errPathNotSet
	}

	if _, err := toml.DecodeFile(t.Path, s); err != nil {
		return err
	}

	return nil
}

// JSONLoader satisifies the loader interface. It loads the configuration from
// the given json file.
type JSONLoader struct {
	Path string
}

func (j *JSONLoader) Load(s interface{}) error {
	if j.Path == "" {
		return errPathNotSet
	}

	file, err := ioutil.ReadFile(j.Path)
	if err != nil {
		return err
	}

	return json.Unmarshal(file, s)
}
