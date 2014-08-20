package config

import (
	"encoding/json"
	"os"

	"github.com/koding/multiconfig"
)

var conf *Config

// Returns config, if it is nil, panics
func MustGet() *Config {
	if conf == nil {
		panic("config is not set, please call Config.MustRead(pathToConfFile)")
	}

	return conf
}

// MustRead takes a relative file path
// and tries to open and read it into Config struct
// If file is not there or file is not given, it panics
// If the given file is not formatted well, panics
func MustRead(path string) *Config {
	conf = &Config{}

	d := &multiconfig.DefaultLoader{
		Loader: multiconfig.MultiLoader(
			&multiconfig.TOMLLoader{Path: path},
			&multiconfig.EnvironmentLoader{Prefix: "KONFIG_SOCIALAPI"},
		),
	}

	d.MustLoad(conf)

	return conf
}

type EnvJSONLoader struct {
	Name string
}

func (e *EnvJSONLoader) Load(s interface{}) error {
	v := os.Getenv(e.Name)
	if v == "" {
		// we are ignoring this case when the config is not set
		// reading a Specific Env key is not mandatory
		return nil
	}

	return json.Unmarshal([]byte(v), s)
}
