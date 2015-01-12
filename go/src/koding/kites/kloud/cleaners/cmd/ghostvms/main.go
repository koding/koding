package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"

	"github.com/koding/multiconfig"
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

	// auth := aws.Auth{
	// 	AccessKey: conf.AccessKey,
	// 	SecretKey: conf.SecretKey,
	// }

	// l := lookup.NewAWS(auth)
	// fmt.Printf("Searching for user VMs in production ...\n")
	//
	// instances := l.FetchInstances().WithTag("koding-env", "production")
	// fmt.Println(instances)
	//
	// fmt.Printf("All regions total: %+v\n", instances.Total())

	m := lookup.NewMongoDB(conf.MongoURL)

	fmt.Printf("Fetching user VMs from MongoDB ...\n")
	instanceIds := make([]string, 0)
	iter := func(l lookup.MachineDocument) error {
		if i, ok := l.Meta["instanceId"]; ok {
			if id, ok := i.(string); ok {
				fmt.Printf("id = %+v\n", id)
				instanceIds = append(instanceIds, id)
			}
		}

		return nil
	}

	if err := m.Iter(iter); err != nil {
		fmt.Printf("err = %+v\n", err)
	}

	fmt.Printf("len(instanceIds) = %+v\n", len(instanceIds))

}
