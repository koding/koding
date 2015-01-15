package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"os"
	"time"

	"github.com/koding/multiconfig"
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
)

type Config struct {
	// AWS Access and Secret Key
	AccessKey string `required:"true"`
	SecretKey string `required:"true"`

	MongoURL string `required:"true"`

	Terminate bool
}

func main() {
	conf := new(Config)

	// Load the config, it's reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	var instances lookup.MultiInstances
	done := make(chan bool, 1)
	go func() {
		auth := aws.Auth{
			AccessKey: conf.AccessKey,
			SecretKey: conf.SecretKey,
		}

		l := lookup.NewAWS(auth)
		start := time.Now()
		fmt.Printf("Searching for user VMs in production ...\n")

		instances = l.FetchInstances().WithTag("koding-env", "production")
		fmt.Println(instances)

		fmt.Printf("AWS instances total: %+v (time: %s)\n",
			instances.Total(), time.Since(start))

		close(done)
	}()

	m := lookup.NewMongoDB(conf.MongoURL)
	fmt.Printf("Fetching user VMs from MongoDB ...\n")
	mongodbIds := make(map[string]struct{}, 0)

	iter := func(l lookup.MachineDocument) {
		i, ok := l.Meta["instanceId"]
		if !ok {
			fmt.Println("instanceId doesn't exist")
			return
		}

		id, ok := i.(string)
		if !ok {
			fmt.Printf("MongoDB meta.instanceId is malformed %v", i)
			return
		}

		if id == "" {
			fmt.Println("instanceId is empty")
			return
		}

		mongodbIds[id] = struct{}{}
	}

	start := time.Now()
	if err := m.Iter(iter); err != nil {
		fmt.Printf("err = %+v\n", err)
	}

	fmt.Printf("MongoDB documents with InstanceId field: %+v (time: %s)\n",
		len(mongodbIds), time.Since(start))

	<-done // wait for AWS

	ghostInstances := make(lookup.MultiInstances, 0)
	instances.Iter(func(client *ec2.EC2, vms lookup.Instances) {
		ghostIds := make(lookup.Instances, 0)

		for id, instance := range vms {
			_, ok := mongodbIds[id]
			// so we have a id that is available on AWS but is not available in
			// MongodB
			if !ok {
				ghostIds[id] = instance
			}
		}

		ghostInstances[client] = ghostIds
	})

	fmt.Printf("\nFound %d instances without any MongoDB document\n", ghostInstances.Total())

	if !conf.Terminate {
		fmt.Printf("To terminate the instances run the command again with the flag -terminate\n")
		os.Exit(0)
	}

	if ghostInstances.Total() > 100 {
		fmt.Fprintf(os.Stderr, "Instance count is more than 100 (have '%d'), aborting termination\n", ghostInstances.Total())
		os.Exit(1)
	}

	ghostInstances.TerminateAll()
	fmt.Printf("Terminated '%d' instances\n", ghostInstances.Total())
}
