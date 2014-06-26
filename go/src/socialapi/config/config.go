package config

import (
	"os"
	"path/filepath"

	"github.com/BurntSushi/toml"
)

var conf *Config

func Get() *Config {
	if conf == nil {
		panic("config is not set, please call Config.MustRead(pathToConfFile)")
	}

	return conf
}

func MustRead(path string) *Config {
	pwd, err := os.Getwd()
	if err != nil {
		panic(err)
	}

	configPath := filepath.Join(pwd, path)
	if _, err := toml.DecodeFile(configPath, &conf); err != nil {
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
