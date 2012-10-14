package config

import (
	"flag"
	"fmt"
	"os"
)

var configs = map[string]Config{
	"default": {
		AmqpUri:    "amqp://guest:x1srTA7!%25Vb%7D$n%7CS@web0.beta.system.aws.koding.com",
		HomePrefix: "/Users/",
		UseLVE:     true,
	},

	"dev": {
		AmqpUri:    "amqp://guest:s486auEkPzvUjYfeFTMQ@zb.koding.com/kite",
		HomePrefix: "/Users/",
		UseLVE:     true,
	},

	"stage": {
		AmqpUri:    "amqp://test:test@web0.beta.system.aws.koding.com",
		HomePrefix: "/Users/",
		UseLVE:     true,
	},

	"prod": {
		AmqpUri:    "amqp://test:test@web0.beta.system.aws.koding.com",
		HomePrefix: "/Users/",
		UseLVE:     true,
	},

	"local-go": {
		AmqpUri:    "amqp://guest:guest@localhost",
		HomePrefix: "/home/",
	},

	"local": {
		AmqpUri:    "amqp://guest:guest@localhost",
		HomePrefix: "/home/",
	},

	"websockets": {
		UseWebsockets: true,
		User:          "koding",
		HomePrefix:    "/home/",
	},
}

type Config struct {
	AmqpUri    string
	HomePrefix string
	UseLVE     bool

	// for webterm's websockets mode
	UseWebsockets bool
	User          string
}

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
