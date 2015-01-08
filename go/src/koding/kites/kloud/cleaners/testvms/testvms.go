package testvms

import (
	"fmt"
	"koding/kites/kloud/multiec2"
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
		values: []string{"sandbox", "dev"},
		clients: multiec2.New(auth, []string{
			"us-east-1",
			"ap-southeast-1",
			"us-west-2",
			"eu-west-1",
		}),
	}
}

// Instances returns all instances that belongs to the given client/region
func (t *testvms) Instances(client *ec2.EC2, env string) ([]ec2.Instance, error) {
	instances := make([]ec2.Instance, 0)

	filter := ec2.NewFilter()
	filter.Add("tag-value", env)

	resp, err := client.InstancesWithOpts([]string{}, filter, nil)
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
			NextToken: nextToken,
		}

		resp, err := client.InstancesWithOpts([]string{}, filter, opts)
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

// Terminate terminates the given instances
func (t *testvms) Terminate(client *ec2.EC2, instances []ec2.Instance) error {
	if len(instances) == 0 {
		return nil // nothing to terminate
	}

	ids := make([]string, len(instances))

	for i, instance := range instances {
		ids[i] = instance.InstanceId
	}

	resp, err := client.TerminateInstances(ids)
	if err != nil {
		return err
	}

	fmt.Printf("resp = %+v\n", resp)
	return nil
}

// Process fetches all instances defined with the tags
func (t *testvms) Process() {
	var wg sync.WaitGroup
	env := "sandbox"

	for region, client := range t.clients.Regions() {
		wg.Add(1)
		go func(region string, client *ec2.EC2) {
			defer wg.Done()

			start := time.Now()
			instances, err := t.Instances(client, env)
			if err != nil {
				fmt.Printf("[%s] fetching error: %s\n", region, err)
				return
			}

			elapsed := time.Since(start)
			fmt.Printf("[%s] instances tagged with '%s': %+v (time: %s)\n",
				region, env, len(instances), elapsed)

			if err := t.Terminate(client, instances); err != nil {
				fmt.Printf("[%s] terminate error: %s\n", region, err)
			}

		}(region, client)
	}

	wg.Wait()
}

// Summary prints a summary of the process
func (t *testvms) Summary() {

}
