package amazon

import (
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/waitstate"
	"github.com/mitchellh/goamz/ec2"
)

// CreateSnapshot creates a new snapshot from the given volumeId and
// description. It waits until it's ready.
func (a *AmazonClient) CreateSnapshot(volumeId, desc string) (*ec2.Snapshot, error) {
	resp, err := a.Client.CreateSnapshot(volumeId, desc)
	if err != nil {
		return nil, err
	}

	snapShot := resp.Snapshot

	checkSnapshot := func(currentPercentage int) (machinestate.State, error) {
		describeResp, err := a.Client.Snapshots([]string{resp.Id}, ec2.NewFilter())
		if err != nil {
			return 0, err
		}

		if describeResp.Snapshots[0].Status != "completed" {
			return machinestate.Pending, nil
		}

		snapShot = describeResp.Snapshots[0]
		return machinestate.Stopped, nil
	}

	ws := waitstate.WaitState{StateFunc: checkSnapshot, DesiredState: machinestate.Stopped}
	if err := ws.Wait(); err != nil {
		return nil, err
	}

	return &snapShot, nil
}

// CreateVolume creates a new volume from the given snapshot id and size. It
// waits until it's ready.
func (a *AmazonClient) CreateVolume(snapshotId, availZone string, size int) (*ec2.Volume, error) {
	volOptions := &ec2.CreateVolume{
		AvailZone:  availZone,
		Size:       int64(size),
		SnapshotId: snapshotId,
		VolumeType: "gp2", // SSD, make this changable later
	}

	volResp, err := a.Client.CreateVolume(volOptions)
	if err != nil {
		return nil, err
	}

	volume := ec2.Volume{}

	checkVolume := func(currentPercentage int) (machinestate.State, error) {
		resp, err := a.Client.Volumes([]string{volResp.VolumeId}, ec2.NewFilter())
		if err != nil {
			return 0, err
		}

		if resp.Volumes[0].Status != "available" {
			return machinestate.Pending, nil
		}

		volume = resp.Volumes[0]
		return machinestate.Stopped, nil
	}

	ws := waitstate.WaitState{StateFunc: checkVolume, DesiredState: machinestate.Stopped}
	if err := ws.Wait(); err != nil {
		return nil, err
	}

	return &volume, nil
}
