package config

import (
	"os"
)

var configs = map[string]Config{
	"default": {
		AmqpUri:      "amqp://guest:x1srTA7!%25Vb%7D$n%7CS@web0.beta.system.aws.koding.com",
		HomePrefix:   "/Users/",
		ShellCommand: []string{"/bin/lve_exec", "/bin/bash"},
	},

	"stage": {
		AmqpUri:      "amqp://stage:#%5B85_%5B*zh7%254;4l6T%5DF!@web0.beta.system.aws.koding.com",
		HomePrefix:   "/Users/",
		ShellCommand: []string{"/bin/lve_exec", "/bin/bash"},
	},

	"local": {
		AmqpUri:      "amqp://guest:guest@localhost",
		HomePrefix:   "/home/",
		ShellCommand: []string{"/bin/bash"},
	},

	"websockets": {
		UseWebsockets: true,
		User:          "koding",
		HomePrefix:    "/home/",
		ShellCommand:  []string{"/bin/bash"},
	},
}

type Config struct {
	AmqpUri      string
	HomePrefix   string
	ShellCommand []string

	// for webterm's websockets mode
	UseWebsockets bool
	User          string
}

var Current Config

func init() {
	profile := "default"
	if len(os.Args) >= 2 {
		profile = os.Args[1]
	}

	var ok bool
	Current, ok = configs[profile]
	if !ok {
		panic("Configuration not found.")
	}
}
