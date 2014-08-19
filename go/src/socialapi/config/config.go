package config

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"

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

func createLoader(path string, flagSet *flag.FlagSet) *multiconfig.DefaultLoader {
	loaders := []multiconfig.Loader{}

	// Choose what while is passed
	if strings.HasSuffix(path, "toml") {
		loaders = append(loaders, &multiconfig.TOMLLoader{Path: path})
	}

	if strings.HasSuffix(path, "json") {
		loaders = append(loaders, &multiconfig.JSONLoader{Path: path})
	}

	loaders = append(loaders,
		&multiconfig.EnvironmentLoader{},
	)

	d := &multiconfig.DefaultLoader{}
	d.Loader = multiconfig.MultiLoader(loaders...)
	return d
}

// MustRead takes a relative file path
// and tries to open and read it into Config struct
// If file is not there or file is not given, it panics
// If the given file is not formatted well, panics
func MustRead(path string, flagSet *flag.FlagSet) *Config {
	conf = &Config{}

	m := createLoader(path, flagSet)
	m.MustLoad(conf)

	// we can override Environment property of
	//the config from env variable
	// set environment variable
	getStringEnvVar(&conf.Environment, "SOCIAL_API_ENV")

	// set URI for webserver
	getStringEnvVar(&conf.Hostname, "SOCIAL_API_HOSTNAME")

	// set host for rabbitMQ
	getStringEnvVar(&conf.Mq.Host, "RABBITMQ_HOST")
	getIntEnvVar(&conf.Mq.Port, "RABBITMQ_PORT")
	getStringEnvVar(&conf.Mq.Login, "RABBITMQ_USERNAME")
	getStringEnvVar(&conf.Mq.Password, "RABBITMQ_PASSWORD")

	// set redis url
	getStringEnvVar(&conf.Redis.URL, "REDIS_URL")

	// set postgresql config
	getStringEnvVar(&conf.Postgres.Host, "POSTGRES_HOST")
	getIntEnvVar(&conf.Postgres.Port, "POSTGRES_PORT")
	getStringEnvVar(&conf.Postgres.DBName, "POSTGRES_DBNAME")
	getStringEnvVar(&conf.Postgres.Username, "POSTGRES_USERNAME")
	getStringEnvVar(&conf.Postgres.Password, "POSTGRES_PASSWORD")

	// set mongo config
	getStringEnvVar(&conf.Mongo, "MONGO_URL")

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
