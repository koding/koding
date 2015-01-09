package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"

	"github.com/koding/multiconfig"
	"github.com/mitchellh/goamz/aws"
)

type Config struct {
	// AWS Access and Secret Key
	AccessKey string `required:"true"`
	SecretKey string `required:"true"`
}

func main() {
	conf := new(Config)

	// Load the config, it's reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	auth := aws.Auth{
		AccessKey: conf.AccessKey,
		SecretKey: conf.SecretKey,
	}

	l := lookup.New(auth)

	fmt.Printf("Searching for user VMs in production ...\n")

	instances := l.FetchInstances()
	instances = instances.WithTag("koding-env", "production")
	fmt.Println(instances)

	fmt.Printf("All regions total: %+v\n", instances.Total())
}
