package main

type Config struct {
	amqpUrl      string
	homePrefix   string
	shellCommand []string

	// for websockets mode
	useWebsockets bool
	user          string
}

var configs = map[string]Config{

	"stage": {
		amqpUrl:      "amqp://stage:#[85_[*zh7%4;4l6T]F!@web0.beta.system.aws.koding.com",
		homePrefix:   "/Users/",
		shellCommand: []string{"/bin/lve_exec", "/bin/bash"},
	},

	"default": {
		amqpUrl:      "amqp://guest:x1srTA7!%25Vb%7D$n%7CS@web0.beta.system.aws.koding.com",
		homePrefix:   "/Users/",
		shellCommand: []string{"/bin/lve_exec", "/bin/bash"},
	},

	"local": {
		amqpUrl:      "amqp://guest:guest@localhost",
		homePrefix:   "/home/",
		shellCommand: []string{"/bin/bash"},
	},

	"websockets": {
		useWebsockets: true,
		user:          "koding",
		homePrefix:    "/home/",
		shellCommand:  []string{"/bin/bash"},
	},
}
