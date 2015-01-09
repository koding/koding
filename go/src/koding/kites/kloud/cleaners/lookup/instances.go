package lookup

import (
	"time"

	"github.com/mitchellh/goamz/ec2"
)

type Instances []ec2.Instance

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

func (i Instances) Split(size int) []Instances {
	return nil
}
