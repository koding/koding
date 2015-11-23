package amazon

import (
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/waitstate"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
)

// CreateSnapshot creates a new snapshot from the given volumeId and
// description. It waits until it's ready.
func (a *Amazon) CreateSnapshot(volumeId, desc string) (*ec2.Snapshot, error) {
	snapshot, err := a.Client.CreateSnapshot(volumeId, desc)
	if err != nil {
		return nil, err
	}

	checkSnapshot := func(int) (machinestate.State, error) {
		s, err := a.Client.SnapshotByID(aws.StringValue(snapshot.SnapshotId))
		if IsNotFound(err) {
			// shouldn't happen but let's check it anyway
			return machinestate.Pending, nil
		}
		if err != nil {
			return 0, err
		}
		if aws.StringValue(s.State) != ec2.SnapshotStateCompleted {
			return machinestate.Pending, nil
		}
		snapshot = s
		return machinestate.Stopped, nil
	}

	ws := waitstate.WaitState{
		StateFunc:    checkSnapshot,
		DesiredState: machinestate.Stopped,
	}
	if err := ws.Wait(); err != nil {
		return nil, err
	}

	return snapshot, nil
}
