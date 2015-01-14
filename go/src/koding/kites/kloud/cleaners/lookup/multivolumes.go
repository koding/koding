package lookup

import (
	"bytes"
	"fmt"
	"text/tabwriter"
	"time"

	"github.com/mitchellh/goamz/ec2"
)

type MultiVolumes map[*ec2.EC2]Volumes

func (m MultiVolumes) GreaterThan(storage int) MultiVolumes {
	filtered := make(MultiVolumes, 0)
	for client, volumes := range m {
		filtered[client] = volumes.GreaterThan(storage)
	}
	return filtered
}

// OlderThan filters out volumes that are older than the given duration.
func (m MultiVolumes) OlderThan(duration time.Duration) MultiVolumes {
	filtered := make(MultiVolumes, 0)
	for client, volumes := range m {
		filtered[client] = volumes.OlderThan(duration)
	}
	return filtered
}

func (m MultiVolumes) Status(status string) MultiVolumes {
	filtered := make(MultiVolumes, 0)
	for client, volumes := range m {
		filtered[client] = volumes.Status(status)
	}
	return filtered
}

// InstanceIds returns a map of instanceIds per region
func (m MultiVolumes) InstanceIds() map[*ec2.EC2][]string {
	instances := make(map[*ec2.EC2][]string, 0)

	for client, volumes := range m {
		instances[client] = volumes.InstaceIds()
	}

	return instances
}

// Total return the number of all instances
func (m MultiVolumes) Total() int {
	total := 0
	for _, volumes := range m {
		total += len(volumes)
	}
	return total
}

// String representation of MultiVolumes
func (m MultiVolumes) String() string {
	fmt.Printf("\n\n")
	w := new(tabwriter.Writer)

	buf := new(bytes.Buffer)
	w.Init(buf, 0, 8, 0, '\t', 0)

	total := 0
	for client, volumes := range m {
		region := client.Region.Name
		fmt.Fprintf(w, "[%s]\t total volumes: %+v \n", region, len(volumes))
		total += len(volumes)
	}

	fmt.Fprintln(w)
	w.Flush()

	return buf.String()
}
