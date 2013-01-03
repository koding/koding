package config

import (
	"fmt"
	"os"
)

var configs = map[string]Config{
	"default": {
		AmqpHost:     "localhost",
		AmqpUser:     "guest",
		AmqpPassword: "guest",
		HomePrefix:   "/Users/",
	},

	"dev": {
		AmqpHost:     "zb.koding.com/kite",
		AmqpUser:     "guest",
		AmqpPassword: "s486auEkPzvUjYfeFTMQ",
		HomePrefix:   "/Users/",
	},

	"dev-new": {
		AmqpHost:     "web0.dev.system.aws.koding.com:5672",
		AmqpUser:     "broker",
		AmqpPassword: "s486auEkPzvUjYfeFTMQ",
		HomePrefix:   "/Users/",
	},

	"dev-new-web0": {
		AmqpHost:     "localhost:5672",
		AmqpUser:     "broker",
		AmqpPassword: "s486auEkPzvUjYfeFTMQ",
		HomePrefix:   "/Users/",
	},

	"cl3-new": {
		AmqpHost:     "web0.dev.system.aws.koding.com:5672",
		AmqpUser:     "guest",
		AmqpPassword: "s486auEkPzvUjYfeFTMQ",
		HomePrefix:   "/Users/",
	},

	"stage": {
		AmqpHost:     "web0.beta.system.aws.koding.com",
		AmqpUser:     "STAGE-sg46lU8J17UkVUq",
		AmqpPassword: "TV678S1WT221t1q",
		HomePrefix:   "/Users/",
		LogToLoggr:   true,
	},

	"prod": {
		AmqpHost:     "web0.beta.system.aws.koding.com",
		AmqpUser:     "prod-<component>",
		AmqpPassword: "Dtxym6fRJXx4GJz",
		HomePrefix:   "/Users/",
		LogToLoggr:   true,
	},

	"prod-new": {
		AmqpHost:     "web0.beta.system.aws.koding.com",
		AmqpUser:     "prod-<component>",
		AmqpPassword: "Dtxym6fRJXx4GJz",
		HomePrefix:   "/Users/",
		LogToLoggr:   true,
	},

	"vagrant": {
		AmqpHost:     "rabbitmq.local",
		AmqpUser:     "prod-<component>",
		AmqpPassword: "djfjfhgh4455__5",
		HomePrefix:   "/Users/",
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
}

type Config struct {
	AmqpHost     string
	AmqpUser     string
	AmqpPassword string
	HomePrefix   string
	LogToLoggr   bool
}

var Current Config

func LoadConfig(profile string) {
	var ok bool
	Current, ok = configs[profile]
	if !ok {
		fmt.Printf("Configuration not found: %v\n", profile)
		os.Exit(1)
	}
}
