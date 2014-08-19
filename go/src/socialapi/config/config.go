package config

import (
	"fmt"
	"os"
	"strconv"

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

func getStringEnvVar(field *string, envVarName string) {
	env := os.Getenv(envVarName)
	if env != "" {
		*field = env
	}
}

func getIntEnvVar(field *int, envVarName string) {
	env := os.Getenv(envVarName)
	if env != "" {
		value, err := strconv.Atoi(env)
		if err != nil {
			panic(fmt.Errorf("couldn't parse env variable: %s", envVarName))
		}
		*field = value
	}
}
