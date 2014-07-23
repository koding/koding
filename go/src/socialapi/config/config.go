package config

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/BurntSushi/toml"
)

var conf *Config

func MustGet() *Config {
	if conf == nil {
		panic("config is not set, please call Config.MustRead(pathToConfFile)")
	}

	return conf
}

// MustRead takes a relative file path
// and tries to open and read it into Config struct
// If file is not there or file is not given, it panics
// If the given file is not formatted well panics
func MustRead(path string) *Config {

	if _, err := toml.DecodeFile(mustGetConfigPath(path), &conf); err != nil {
		panic(err)
	}

	// we can override Environment property of
	//the config from env variable
	// set environment variable
	env := os.Getenv("SOCIAL_API_ENV")
	if env != "" {
		conf.Environment = env
	}

	// set URI for webserver
	hostname := os.Getenv("SOCIAL_API_HOSTNAME")
	if hostname != "" {
		conf.Uri = hostname
	}

	return conf
}

func mustGetConfigPath(path string) string {
	pwd, err := os.Getwd()
	if err != nil {
		panic(err)
	}

	configPath := filepath.Join(pwd, path)

	// check if file with combined path is exists
	if _, err := os.Stat(configPath); !os.IsNotExist(err) {
		return configPath
	}

	// check if file is exists it self
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		return path
	}

	panic(fmt.Errorf("couldn't find config with given parameter %s", path))
}
