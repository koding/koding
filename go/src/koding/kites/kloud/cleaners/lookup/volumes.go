package lookup

import (
	"bytes"
	"fmt"
	"strconv"
	"text/tabwriter"

	"github.com/mitchellh/goamz/ec2"
)

type Volumes map[string]ec2.Volume

func (v Volumes) GreaterThan(storage int) Volumes {
	filtered := make(Volumes, 0)

	for id, volume := range v {
		volSize, err := strconv.Atoi(volume.Size)
		if err != nil {
			fmt.Printf("volume err = %+v\n", err)
			continue
		}

		if volSize > storage {
			filtered[id] = volume
		}
	}

	return filtered
}

// InstanceIds returns a
func (v Volumes) InstaceIds() []string {
	ids := make([]string, 0)

	for _, volume := range v {
		if volume.Attachments == nil {
			continue
		}

		if len(volume.Attachments) == 1 {
			ids = append(ids, volume.Attachments[0].InstanceId)
		} else if len(volume.Attachments) > 1 {
			fmt.Printf("volume = %+v\n", volume)
			panic("No VM should have more than one volume. Something is wrong!!!")
		}
	}

	return ids
}

type MultiVolumes map[*ec2.EC2]Volumes

func (m MultiVolumes) GreaterThan(storage int) MultiVolumes {
	filtered := make(MultiVolumes, 0)
	for client, volumes := range m {
		filtered[client] = volumes.GreaterThan(storage)
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

// Total return the number of al instances
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
