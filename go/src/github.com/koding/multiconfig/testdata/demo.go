package main

import "github.com/koding/multiconfig"

type (
	Server struct {
		Name     string
		Port     int
		Enabled  bool
		Users    []string
		Postgres Postgres
	}

	// Postgres holds Postgresql database related configuration
	Postgres struct {
		Enabled           bool
		Port              int
		Hosts             []string
		DBName            string
		AvailabilityRatio float64
	}
)

func main() {
	m := multiconfig.NewWithPath("config.toml") // supports TOML and JSON

	// Get an empty struct for your configuration
	serverConf := new(Server)

	// Populated the serverConf struct
	m.MustLoad(serverConf) // Check for error
}
