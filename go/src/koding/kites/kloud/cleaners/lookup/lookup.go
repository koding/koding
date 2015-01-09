package lookup

import (
	"fmt"
	"koding/kites/kloud/multiec2"
	"sync"
	"time"

	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
)

type Lookup struct {
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

func New(auth aws.Auth, envs []string, olderThan time.Duration) *Lookup {
	return &Lookup{
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
func (l *Lookup) Instances(client *ec2.EC2) ([]ec2.Instance, error) {
	instances := make(Instances, 0)

	filter := ec2.NewFilter()
	filter.Add("tag-value", l.values...)

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

	return instances.OlderThan(l.olderThan), nil
}

// TerminateAll terminates all found instances
func (l *Lookup) TerminateAll() {
	if l.FoundInstances == nil {
		return
	}

	var wg sync.WaitGroup

	for client, instances := range l.FoundInstances {
		wg.Add(1)

		go func(client *ec2.EC2, instances []ec2.Instance) {
			l.Terminate(client, instances)
			wg.Done()
		}(client, instances)
	}

	wg.Wait()
}

// Terminate terminates the given instances
func (l *Lookup) Terminate(client *ec2.EC2, instances []ec2.Instance) {
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
func (l *Lookup) Process() {
	var wg sync.WaitGroup

	for region, client := range l.clients.Regions() {
		wg.Add(1)
		go func(region string, client *ec2.EC2) {
			defer wg.Done()

			instances, err := l.Instances(client)
			if err != nil {
				fmt.Printf("[%s] fetching error: %s\n", region, err)
				return
			}

			l.FoundInstances[client] = instances
		}(region, client)
	}

	wg.Wait()
}
