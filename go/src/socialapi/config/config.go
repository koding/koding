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

	return conf
}
