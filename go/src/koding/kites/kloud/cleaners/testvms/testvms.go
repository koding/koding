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
	// olderThan defines the duration in which instances are fetched. By
	// default all instances (new and old) are fetched.
	olderThan time.Duration

	// values contains a list of instance tags that are identified as test
	// instances. By default all instances are fetched.
	values []string

	// dryRun runs the process but doesn't do anything. It's usefull to check
	// before terminating all instances. By default it's disabled.
	dryRun bool

	clients *multiec2.Clients
}

func New(envs []string, olderThan time.Duration, dryRun bool) *testvms {
	// Credential belongs to the `koding-kloud` user in AWS IAM's
	auth := aws.Auth{
		AccessKey: "AKIAJFKDHRJ7Q5G4MOUQ",
		SecretKey: "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",
	}

	return &testvms{
		olderThan: olderThan,
		values:    envs,
		dryRun:    dryRun,
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

	filter := ec2.NewFilter()
	filter.Add("tag-value", t.values...)

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

		for _, res := range resp.Reservations {
			instances = append(instances, res.Instances...)
		}

		nextToken = resp.NextToken
	}

	filtered := make([]ec2.Instance, 0)

	for _, instance := range instances {
		oldDate := time.Now().UTC().Add(-t.olderThan)
		if instance.LaunchTime.Before(oldDate) {
			filtered = append(filtered, instance)
		}
	}

	instances = nil

	return filtered, nil
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

	// we split the ids because AWS doesn't allow us to terminate more than
	// 1000 instances, so for example if we have 2570 instances, we'll going to
	// make three API calls with ids of 1000, 1000 and 570
	var splitted [][]string
	for len(ids) >= 1000 {
		splitted = append(splitted, ids[:1000])
		ids = ids[1000:]
	}
	splitted = append(splitted, ids) // remaining

	for _, split := range splitted {
		_, err := client.TerminateInstances(split)
		if err != nil {
			fmt.Println(err)
		}
	}

	return nil
}

// Process fetches all instances defined with the tags
func (t *testvms) Process() {
	var wg sync.WaitGroup

	fmt.Printf("Searching for instances tagged with %+v and older than: %s\n\n", t.values, t.olderThan)

	for region, client := range t.clients.Regions() {
		wg.Add(1)
		go func(region string, client *ec2.EC2) {
			defer wg.Done()

			start := time.Now()
			instances, err := t.Instances(client)
			if err != nil {
				fmt.Printf("[%s] fetching error: %s\n", region, err)
				return
			}

			elapsed := time.Since(start)
			fmt.Printf("[%s] total instances: %+v (time: %s)\n",
				region, len(instances), elapsed)

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
