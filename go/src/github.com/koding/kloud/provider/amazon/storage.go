package amazon

import (
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/waitstate"
	"github.com/mitchellh/goamz/ec2"
)

// CreateSnapshot creates a new snapshot from the given volumeId and
// description.
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
