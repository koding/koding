package lookup

import (
	"fmt"
	"time"

	"github.com/mitchellh/goamz/ec2"
)

// Instances represents a list of ec2.Instances
type Instances []ec2.Instance

// OlderThan filters out instances that are older than the given duration.
func (i Instances) OlderThan(duration time.Duration) Instances {
	filtered := make(Instances, 0)

	for _, instance := range i {
		oldDate := time.Now().UTC().Add(-duration)

		if instance.LaunchTime.Before(oldDate) {
			filtered = append(filtered, instance)
		}
	}

	return filtered
}

// WithTag filters out instances which contains that particular tag's key and
// corresponding values
func (i Instances) WithTag(key string, values ...string) Instances {
	filtered := make(Instances, 0)

	valueIn := func(value string, values ...string) bool {
		for _, v := range values {
			if v == value {
				return true
			}
		}
		return false
	}

	for _, instance := range i {
		for _, tag := range instance.Tags {
			if tag.Key == key && valueIn(tag.Value, values...) {
				filtered = append(filtered, instance)
			}
		}
	}

	return filtered
}

// Ids returns the list of ids of the instances,
func (i Instances) Ids() []string {
	ids := make([]string, len(i))

	for i, instance := range i {
		ids[i] = instance.InstanceId
	}

	return ids
}

// Terminate terminates all instances
func (i Instances) Terminate(client *ec2.EC2) {
	if len(i) == 0 {
		return
	}

	for _, split := range i.SplittedIds(500) {
		_, err := client.TerminateInstances(split)
		if err != nil {
			fmt.Printf("[%s] terminate error: %s\n", client.Region.Name, err)
		}
	}
}

// SplittedIds splits the instances ids into a list of ids each with the given
// split capacity
func (i Instances) SplittedIds(split int) [][]string {
	if split == 0 {
		panic("split number must be greater than 0")
	}

	ids := i.Ids()

	// we split the ids because AWS doesn't allow us to terminate more than 500
	// instances, so for example if we have 1890 instances, we'll going to make
	// four API calls with ids of 500, 500, 500 and 390
	var splitted [][]string
	for len(ids) >= split {
		splitted = append(splitted, ids[:split])
		ids = ids[split:]
	}
	splitted = append(splitted, ids) // remaining

	return splitted
}
