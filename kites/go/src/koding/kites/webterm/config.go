package main

type Config struct {
	amqpUrl       string
	homePrefix    string
	shellCommand  []string
	
	// for websockets mode
	useWebsockets bool
	user          string
}

var configs = map[string]Config{

	"default": {
		amqpUrl:      "amqp://guest:x1srTA7!%25Vb%7D$n%7CS@web0.beta.system.aws.koding.com",
		homePrefix:   "/Users/",
		shellCommand: []string{"/bin/lve_wrapper", "/bin/bash"},
	},
	
	"local": {
		amqpUrl:      "amqp://guest:x1srTA7!%25Vb%7D$n%7CS@web0.beta.system.aws.koding.com",
		homePrefix:   "/home/",
		shellCommand: []string{"/bin/bash"},
	},
	
	"websockets": {
    useWebsockets: true,
    user:          "richard",
		homePrefix:    "/home/",
		shellCommand:  []string{"/bin/bash"},
	},
	
}
