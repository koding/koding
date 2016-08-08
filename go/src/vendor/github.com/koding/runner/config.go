package runner

import "github.com/koding/multiconfig"

var (
	conf *Config
)

type (
	// Config holds all the configuration variables of socialapi
	Config struct {
		// Postres holds connection credentials for postgresql
		Postgres Postgres

		// Mq holds connction credentials for rabbitmq
		Mq Mq

		// Redis holds connection string for redis
		Redis Redis

		// Environment holds the environment of the the running application
		Environment string

		// Region holds the region of the the running application
		Region string

		// Hostname is the web end point the app
		Hostname string

		// random access configs
		EventExchangeName string
		DisableCaching    bool
		Debug             bool

		Host string
		Port string

		// Path holds the config file's path
		Path string
	}

	// Postgres holds Postgresql database related configuration
	Postgres struct {
		Host     string
		Port     string
		Username string
		Password string
		DBName   string
	}

	// Mq holds Rabbitmq related configuration
	Mq struct {
		Host     string
		Port     int
		Login    string
		Password string
		Vhost    string
	}

	// Redis holds Redis related config
	Redis struct {
		URL string
		DB  int
	}
)

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

	loaders := []multiconfig.Loader{}

	if path != "" {
		tomlLoader := &multiconfig.TOMLLoader{Path: path}
		loaders = append(loaders, tomlLoader)
	}

	envLoader := &multiconfig.EnvironmentLoader{Prefix: "KONFIG_SOCIALAPI"}
	loaders = append(loaders, envLoader)

	d := &multiconfig.DefaultLoader{
		Loader: multiconfig.MultiLoader(loaders...),
	}

	if err := d.Load(conf); err != nil {
		panic(err)
	}

	return conf
}
