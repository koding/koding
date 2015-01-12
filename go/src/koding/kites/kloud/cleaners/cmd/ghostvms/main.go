package main

import (
	"errors"
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
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
}

func main() {
	conf := new(Config)

	// Load the config, it's reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	var instances *lookup.MultiInstances
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

	iter := func(l lookup.MachineDocument) error {
		i, ok := l.Meta["instanceId"]
		if !ok {
			return errors.New("instanceId doesn't exist")
		}

		id, ok := i.(string)
		if !ok {
			return fmt.Errorf("MongoDB meta.instanceId is malformed %v", i)
		}

		if id == "" {
			return errors.New("instanceId is empty")
		}

		mongodbIds[id] = struct{}{}
		return nil
	}

	start := time.Now()
	if err := m.Iter(iter); err != nil {
		fmt.Printf("err = %+v\n", err)
	}

	<-done // wait for AWS

	fmt.Printf("MongoDB documents with InstanceId field: %+v (time: %s)\n",
		len(mongodbIds), time.Since(start))

	fmt.Printf("\nInstances without any MongoDB document: \n")

	instances.Iter(func(client *ec2.EC2, vms lookup.Instances) {
		for id := range vms {
			_, ok := mongodbIds[id]
			// so we have a id that is available on AWS but is not available in
			// MongodB
			if !ok {
				fmt.Printf("\t[%s] %s\n", client.Region.Name, id)
			}
		}
	})

}
