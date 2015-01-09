package lookup

import (
	"time"

	"github.com/mitchellh/goamz/ec2"
)

// Instances represents a list of ec2.Instances
type Instances []ec2.Instance

// OlderThan filters out instances that are older than the given duration.
func (i Instances) OlderThan(duration time.Duration) Instances {
	filtered := make(Instances, 0)

	// filter out instances that are older
	for _, instance := range i {
		oldDate := time.Now().UTC().Add(-duration)

		if instance.LaunchTime.Before(oldDate) {
			filtered = append(filtered, instance)
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
