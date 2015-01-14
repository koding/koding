package lookup

import (
	"fmt"
	"strconv"

	"github.com/mitchellh/goamz/ec2"
)

type Volumes map[string]ec2.Volume

// GreaterTan filters out volumes which are greater than the given storage size
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

// Status filters out volumes which are equal to the given status
func (v Volumes) Status(status string) Volumes {
	filtered := make(Volumes, 0)

	for id, volume := range v {
		if volume.Status == status {
			filtered[id] = volume
		}
	}

	return filtered

}

// InstanceIds returns the list of instances ids for the respective volumes
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
