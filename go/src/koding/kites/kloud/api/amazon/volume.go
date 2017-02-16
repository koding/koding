package amazon

import (
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/waitstate"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
)

// ExistingVolume retrieves the volume for the given existing volume ID. This
// can be used instead of the plain a.Client.Volumes, because the plain method
// returns "(InvalidVolume.NotFound)" even if the volume exists. This method
// tries for one minute to get a successful response(errors are neglected), so
// try this only if the Volume exists.
func (a *Amazon) ExistingVolume(volumeID string) (vol *ec2.Volume, err error) {
	getVolume := func(currentPercentage int) (machinestate.State, error) {
		vol, err = a.Client.VolumeByID(volumeID)
		if err != nil {
			return machinestate.Pending, nil // we don't return until we get a result
		}
		return machinestate.Running, nil
	}

	ws := waitstate.WaitState{
		StateFunc:    getVolume,
		DesiredState: machinestate.Running,
		Timeout:      time.Minute,
	}
	if err := ws.Wait(); err != nil {
		return nil, err
	}

	return vol, nil
}

// CreateVolume creates a new volume from the given snapshot id and size. It
// waits until it's ready.
func (a *Amazon) CreateVolume(snapshotID, availZone, volumeType string, size int) (vol *ec2.Volume, err error) {
	v, err := a.Client.CreateVolume(snapshotID, availZone, volumeType, int64(size))
	if err != nil {
		return nil, err
	}

	checkVolume := func(currentPercentage int) (machinestate.State, error) {
		vol, err = a.Client.VolumeByID(aws.StringValue(v.VolumeId))
		if err != nil {
			return 0, err
		}

		if aws.StringValue(vol.State) != "available" {
			return machinestate.Pending, nil
		}

		return machinestate.Stopped, nil // TODO(rjeczalik): Attached?
	}

	ws := waitstate.WaitState{
		StateFunc:    checkVolume,
		DesiredState: machinestate.Stopped,
	}
	if err := ws.Wait(); err != nil {
		return nil, err
	}

	return vol, nil
}

// DetachVolume detach the given volumeID. It waits until it's ready.
func (a *Amazon) DetachVolume(volumeID string) error {
	if err := a.Client.DetachVolume(volumeID); err != nil {
		return err
	}

	checkDetaching := func(currentPercentage int) (machinestate.State, error) {
		vol, err := a.Client.VolumeByID(volumeID)
		if err != nil {
			return 0, err
		}

		// ready!
		if len(vol.Attachments) == 0 {
			return machinestate.Stopped, nil
		}

		// otherwise wait until it's detached
		if aws.StringValue(vol.Attachments[0].State) != "detached" {
			return machinestate.Pending, nil
		}

		return machinestate.Stopped, nil
	}

	ws := waitstate.WaitState{
		StateFunc:    checkDetaching,
		DesiredState: machinestate.Stopped,
	}
	return ws.Wait()
}

// AttachVolume attach the given volumeID to the instance. DevicePath defines
// the root path of the volume such as /dev/sda1. It waits until it's ready.
func (a *Amazon) AttachVolume(volumeID, instanceID, devicePath string) error {
	if err := a.Client.AttachVolume(volumeID, instanceID, devicePath); err != nil {
		return err
	}

	checkAttaching := func(currentPercentage int) (machinestate.State, error) {
		vol, err := a.Client.VolumeByID(volumeID)
		if err != nil {
			return 0, err
		}

		if len(vol.Attachments) == 0 {
			return machinestate.Pending, nil
		}

		if aws.StringValue(vol.Attachments[0].State) != "attached" {
			return machinestate.Pending, nil
		}

		return machinestate.Stopped, nil
	}

	ws := waitstate.WaitState{
		StateFunc:    checkAttaching,
		DesiredState: machinestate.Stopped,
	}
	return ws.Wait()
}
