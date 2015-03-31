package amazon

import (
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/waitstate"

	"github.com/mitchellh/goamz/ec2"
)

func (a *Amazon) DeleteSnapshot(snapshotId string) error {
	_, err := a.Client.DeleteSnapshots([]string{snapshotId})
	return err
}

// CreateSnapshot creates a new snapshot from the given volumeId and
// description. It waits until it's ready.
func (a *Amazon) CreateSnapshot(volumeId, desc string) (*ec2.Snapshot, error) {
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

		// shouldn't happen but let's check it anyway
		if len(describeResp.Snapshots) == 0 {
			return machinestate.Pending, nil
		}

		if describeResp.Snapshots[0].Status != "completed" {
			return machinestate.Pending, nil
		}

		snapShot = describeResp.Snapshots[0]
		return machinestate.Stopped, nil
	}

	ws := waitstate.WaitState{
		StateFunc:    checkSnapshot,
		DesiredState: machinestate.Stopped,
	}
	if err := ws.Wait(); err != nil {
		return nil, err
	}

	return &snapShot, nil
}
