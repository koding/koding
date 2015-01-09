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
	OlderThan time.Duration

	// values contains a list of instance tags that are identified as test
	// instances. By default all instances are fetched.
	values []string

	// FoundInstances is a list of instances that are fetched and stored
	FoundInstances map[*ec2.EC2]Instances

	// filter is used to filter instances
	Filter *ec2.Filter

	clients *multiec2.Clients
}

func New(auth aws.Auth) *Lookup {
	return &Lookup{
		clients: multiec2.New(auth, []string{
			"us-east-1",
			"ap-southeast-1",
			"us-west-2",
			"eu-west-1",
		}),
		FoundInstances: make(map[*ec2.EC2]Instances),
	}
}

// Instances returns all instances that belongs to the given client/region if
func (l *Lookup) Instances(client *ec2.EC2) (Instances, error) {
	instances := make(Instances, 0)

	resp, err := client.InstancesWithOpts([]string{}, l.Filter, nil)
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

		resp, err := client.InstancesWithOpts([]string{}, l.Filter, opts)
		if err != nil {
			return nil, err
		}

		for _, res := range resp.Reservations {
			instances = append(instances, res.Instances...)
		}

		nextToken = resp.NextToken
	}

	if l.OlderThan != 0 {
		return instances.OlderThan(l.OlderThan), nil
	}

	return instances, nil
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
func (l *Lookup) Terminate(client *ec2.EC2, instances Instances) {
	if len(instances) == 0 {
		return
	}

	for _, split := range instances.SplittedIds(500) {
		_, err := client.TerminateInstances(split)
		if err != nil {
			fmt.Printf("[%s] terminate error: %s\n", client.Region.Name, err)
		}
	}
}

// FetchInstances fetches all instances from all regions
func (l *Lookup) FetchInstances() {
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
