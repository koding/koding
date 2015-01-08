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

	// FoundInstances is a list of instances that are fetched and stored
	FoundInstances map[*ec2.EC2][]ec2.Instance

	clients *multiec2.Clients
}

func New(envs []string, olderThan time.Duration) *testvms {
	// Credential belongs to the `koding-kloud` user in AWS IAM's
	auth := aws.Auth{
		AccessKey: "AKIAJFKDHRJ7Q5G4MOUQ",
		SecretKey: "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",
	}

	return &testvms{
		olderThan: olderThan,
		values:    envs,
		clients: multiec2.New(auth, []string{
			"us-east-1",
			"ap-southeast-1",
			"us-west-2",
			"eu-west-1",
		}),
		FoundInstances: make(map[*ec2.EC2][]ec2.Instance),
	}
}

// Instances returns all instances that belongs to the given client/region
func (t *testvms) Instances(client *ec2.EC2) ([]ec2.Instance, error) {
	instances := make([]ec2.Instance, 0)

	filter := ec2.NewFilter()
	filter.Add("tag-value", t.values...)

	// Anything except "terminated" and "shutting-down"
	filter.Add("instance-state-name", "pending", "running", "stopping", "stopped")

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

	// filter out instances that are older
	for _, instance := range instances {
		oldDate := time.Now().UTC().Add(-t.olderThan)
		if instance.LaunchTime.Before(oldDate) {
			filtered = append(filtered, instance)
		}
	}

	instances = nil

	return filtered, nil
}

// TerminateAll terminates all found instances
func (t *testvms) TerminateAll() {
	if t.FoundInstances == nil {
		return
	}

	var wg sync.WaitGroup

	for client, instances := range t.FoundInstances {
		wg.Add(1)

		go func(client *ec2.EC2, instances []ec2.Instance) {
			t.Terminate(client, instances)
			wg.Done()
		}(client, instances)
	}

	wg.Wait()
}

// Terminate terminates the given instances
func (t *testvms) Terminate(client *ec2.EC2, instances []ec2.Instance) {
	if len(instances) == 0 {
		return
	}

	ids := make([]string, len(instances))

	for i, instance := range instances {
		ids[i] = instance.InstanceId
	}

	// we split the ids because AWS doesn't allow us to terminate more than 500
	// instances, so for example if we have 1890 instances, we'll going to make
	// four API calls with ids of 500, 500, 500 and 390
	var splitted [][]string
	for len(ids) >= 500 {
		splitted = append(splitted, ids[:500])
		ids = ids[500:]
	}
	splitted = append(splitted, ids) // remaining

	for _, split := range splitted {
		_, err := client.TerminateInstances(split)
		if err != nil {
			fmt.Printf("[%s] terminate error: %s\n", client.Region.Name, err)
		}
	}
}

// Process fetches all instances defined with the tags
func (t *testvms) Process() {
	var wg sync.WaitGroup

	for region, client := range t.clients.Regions() {
		wg.Add(1)
		go func(region string, client *ec2.EC2) {
			defer wg.Done()

			instances, err := t.Instances(client)
			if err != nil {
				fmt.Printf("[%s] fetching error: %s\n", region, err)
				return
			}

			t.FoundInstances[client] = instances
		}(region, client)
	}

	wg.Wait()
}
