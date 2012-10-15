package config

import (
	"flag"
	"fmt"
	"os"
)

var configs = map[string]Config{
	"default": {
		AmqpHost:     "web0.beta.system.aws.koding.com",
		AmqpUser:     "guest",
		AmqpPassword: "x1srTA7!%25Vb%7D$n%7CS",
		HomePrefix:   "/Users/",
		UseLVE:       true,
	},

	"dev": {
		AmqpHost:     "zb.koding.com/kite",
		AmqpUser:     "guest",
		AmqpPassword: "s486auEkPzvUjYfeFTMQ",
		HomePrefix:   "/Users/",
		UseLVE:       true,
	},

	"stage": {
		AmqpHost:     "web0.beta.system.aws.koding.com",
		AmqpUser:     "test",
		AmqpPassword: "test",
		HomePrefix:   "/Users/",
		UseLVE:       true,
	},

	"prod": {
		AmqpHost:     "web0.beta.system.aws.koding.com",
		AmqpUser:     "test",
		AmqpPassword: "test",
		HomePrefix:   "/Users/",
		UseLVE:       true,
	},

	"local-go": {
		AmqpHost:     "localhost",
		AmqpUser:     "guest",
		AmqpPassword: "guest",
		HomePrefix:   "/home/",
	},

	"local": {
		AmqpHost:     "localhost",
		AmqpUser:     "guest",
		AmqpPassword: "guest",
		HomePrefix:   "/home/",
	},

	"websockets": {
		UseWebsockets: true,
		User:          "koding",
		HomePrefix:    "/home/",
	},
}

type Config struct {
	AmqpHost     string
	AmqpUser     string
	AmqpPassword string
	HomePrefix   string
	UseLVE       bool

	// for webterm's websockets mode
	UseWebsockets bool
	User          string
}

const COMPONENT_SPECIFIC = "component-specific"

var Profile string
var Current Config

func init() {
	flag.StringVar(&Profile, "c", "", "Configuration profile")
}

func LoadConfig() {
	if Profile == "" {
		fmt.Println("Please specify a configuration profile (-c).")
		flag.PrintDefaults()
		os.Exit(1)
	}
	var ok bool
	Current, ok = configs[Profile]
	if !ok {
		fmt.Printf("Configuration not found: %v\n", Profile)
		os.Exit(1)
	}
}
