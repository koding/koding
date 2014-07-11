package config

import (
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
	// get working directory for joining with given config path
	pwd, err := os.Getwd()
	if err != nil {
		panic(err)
	}

//join working dir and config path
	configPath := filepath.Join(pwd, path)
	if _, err := toml.DecodeFile(configPath, &conf); err != nil {
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
