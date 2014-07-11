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

func MustRead(path string) *Config {

	if _, err := toml.DecodeFile(mustGetConfigPath(path), &conf); err != nil {
		panic(err)
	}

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
