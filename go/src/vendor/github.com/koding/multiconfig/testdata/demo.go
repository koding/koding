// main package demonstrates the usage of the multiconfig package
package main

import (
	"fmt"

	"github.com/koding/multiconfig"
)

type (
	// Server holds supported types by the multiconfig package
	Server struct {
		Name     string
		Port     int `default:"6060"`
		Enabled  bool
		Users    []string
		Postgres Postgres
	}

	// Postgres is here for embedded struct feature
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

	fmt.Println("After Loading: ")
	fmt.Printf("%+v\n", serverConf)

	if serverConf.Enabled {
		fmt.Println("Enabled field is set to true")
	} else {
		fmt.Println("Enabled field is set to false")
	}
}
