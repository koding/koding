package testvms

import (
	"fmt"
	"koding/kites/kloud/multiec2"
	"log"
	"sync"
	"time"

	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
)

type testvms struct {
	// tags contains a list of instance tags that are identified as test
	// instances
	tag    string
	values []string

	clients *multiec2.Clients
}

func New() *testvms {
	// Credential belongs to the `koding-kloud` user in AWS IAM's
	auth := aws.Auth{
		AccessKey: "AKIAJFKDHRJ7Q5G4MOUQ",
		SecretKey: "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",
	}

	return &testvms{
		tag:    "koding-env",
		values: []string{"sandbox", "development"},
		clients: multiec2.New(auth, []string{
			"us-east-1",
			"ap-southeast-1",
			"us-west-2",
			"eu-west-1",
		}),
	}
}

// Instances returns all instances that belongs to the given client/region
func (t *testvms) Instances(client *ec2.EC2) ([]ec2.Instance, error) {
	instances := make([]ec2.Instance, 0)

	opts := &ec2.InstancesOpts{MaxResults: 500}
	resp, err := client.InstancesWithOpts([]string{}, ec2.NewFilter(), opts)
	if err != nil {
		return nil, err
	}

	for _, res := range resp.Reservations {
		instances = append(instances, res.Instances...)
	}

	nextToken := resp.NextToken

	// get all results until nextToken is empty
	for nextToken != "" {
		opts := &ec2.InstancesOpts{
			MaxResults: 500,
			NextToken:  nextToken,
		}

		resp, err := client.InstancesWithOpts([]string{}, ec2.NewFilter(), opts)
		if err != nil {
			return nil, err
		}

		nextToken = resp.NextToken
		for _, res := range resp.Reservations {
			instances = append(instances, res.Instances[0])
		}
	}

	return instances, nil
}

// Process fetches all instances defined with the tags
func (t *testvms) Process() {
	var wg sync.WaitGroup

	for region, client := range t.clients.Regions() {
		wg.Add(1)
		go func(region string, client *ec2.EC2) {
			fmt.Printf("[%s] fetching instances ...\n", region)
			start := time.Now()
			instances, err := t.Instances(client)
			if err != nil {
				log.Println("err", err)
				return
			}

			elapsed := time.Since(start)
			fmt.Printf("[%s]: total instances: %+v (time: %s)\n", region, len(instances), elapsed)

			wg.Done()
		}(region, client)
	}

	wg.Wait()
}

func (t *testvms) Summary() {}
