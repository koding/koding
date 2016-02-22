package lookup

import (
	"fmt"
	"koding/kites/kloud/api/amazon"
	"sync"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
)

type Volumes map[string]*ec2.Volume

// GreaterTan filters out volumes which are greater than the given storage size
func (v Volumes) GreaterThan(storage int) Volumes {
	filtered := make(Volumes, 0)

	for id, volume := range v {
		if aws.Int64Value(volume.Size) > int64(storage) {
			filtered[id] = volume
		}
	}

	return filtered
}

// OlderThan filters out volumes that are older than the given duration.
func (v Volumes) OlderThan(duration time.Duration) Volumes {
	filtered := make(Volumes, 0)

	for id, volume := range v {
		oldDate := time.Now().UTC().Add(-duration)

		if volume.CreateTime.Before(oldDate) {
			filtered[id] = volume
		}
	}

	return filtered
}

// Size returns the given volume ids size. Returns 0 if the size is not
// available
func (v Volumes) SizeFromVolumeId(id string) int {
	vol, ok := v[id]
	if !ok {
		return 0
	}
	return int(aws.Int64Value(vol.Size))
}

// Ids returns the list of volumeIds of the volumes
func (v Volumes) Ids() []string {
	ids := make([]string, 0)

	for id := range v {
		ids = append(ids, id)
	}

	return ids
}

// Status filters out volumes which are equal to the given status
func (v Volumes) Status(status string) Volumes {
	filtered := make(Volumes, 0)

	for id, volume := range v {
		if aws.StringValue(volume.State) == status {
			filtered[id] = volume
		}
	}

	return filtered

}

// Terminate terminates the given volume specified with the volume id
func (v Volumes) TerminateAll(client *amazon.Client) {
	if len(v) == 0 {
		return
	}

	var wg sync.WaitGroup
	for id := range v {
		wg.Add(1)
		go func(id string) {
			client.DeleteVolume(id)
			wg.Done()
		}(id)
	}

	wg.Wait()
}

// InstanceIds returns the list of instances ids for the respective volumes
func (v Volumes) InstanceIds() map[string]string {
	ids := make(map[string]string, 0)

	for id, volume := range v {
		if volume.Attachments == nil {
			continue
		}

		if len(volume.Attachments) == 1 {
			ids[aws.StringValue(volume.Attachments[0].InstanceId)] = id
		} else if len(volume.Attachments) > 1 {
			fmt.Printf("volume = %+v\n", volume)
			panic("No VM should have more than one volume. Something is wrong!!!")
		}
	}

	return ids
}
