package amazon

import (
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/waitstate"
	"time"

	"github.com/mitchellh/goamz/ec2"
)

// ExistingVolume retrieves the volume for the given existing volume ID. This
// can be used instead of the plain a.Client.Volumes, because the plain method
// returns "(InvalidVolume.NotFound)" even if the volume exists. This method
// tries for one minute to get a successfull response(errors are neglected), so
// try this only if the Volume exists.
func (a *Amazon) ExistingVolume(volumeID string) (*ec2.Volume, error) {
	volume := ec2.Volume{}
	getVolume := func(currentPercentage int) (machinestate.State, error) {
		resp, err := a.Client.Volumes([]string{volumeID}, ec2.NewFilter())
		if err != nil {
			return machinestate.Pending, nil // we don't return until we get a result
		}

		// shouldn't happen but let's check it anyway
		if len(resp.Volumes) == 0 {
			return machinestate.Pending, nil
		}

		volume = resp.Volumes[0]
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

	return &volume, nil
}

// CreateVolume creates a new volume from the given snapshot id and size. It
// waits until it's ready.
func (a *Amazon) CreateVolume(snapshotId, availZone, volumeType string, size int) (*ec2.Volume, error) {
	volOptions := &ec2.CreateVolume{
		AvailZone:  availZone,
		Size:       int64(size),
		SnapshotId: snapshotId,
		VolumeType: volumeType,
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

		// shouldn't happen but let's check it anyway
		if len(resp.Volumes) == 0 {
			return machinestate.Pending, nil
		}

		if resp.Volumes[0].Status != "available" {
			return machinestate.Pending, nil
		}

		volume = resp.Volumes[0]
		return machinestate.Stopped, nil
	}

	ws := waitstate.WaitState{
		StateFunc:    checkVolume,
		DesiredState: machinestate.Stopped,
	}
	if err := ws.Wait(); err != nil {
		return nil, err
	}

	return &volume, nil
}

// DetachVolume detach the given volumeId. It waits until it's ready.
func (a *Amazon) DetachVolume(volumeId string) error {
	if _, err := a.Client.DetachVolume(volumeId); err != nil {
		return err
	}

	checkDetaching := func(currentPercentage int) (machinestate.State, error) {
		resp, err := a.Client.Volumes([]string{volumeId}, ec2.NewFilter())
		if err != nil {
			return 0, err
		}
		vol := resp.Volumes[0]

		// ready!
		if len(vol.Attachments) == 0 {
			return machinestate.Stopped, nil
		}

		// otherwise wait until it's detached
		if vol.Attachments[0].Status != "detached" {
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

// AttachVolume attach the given volumeId to the instance. DevicePath defines
// the root path of the volume such as /dev/sda1. It waits until it's ready.
func (a *Amazon) AttachVolume(volumeId, instanceId, devicePath string) error {
	if _, err := a.Client.AttachVolume(volumeId, instanceId, devicePath); err != nil {
		return err
	}

	checkAttaching := func(currentPercentage int) (machinestate.State, error) {
		resp, err := a.Client.Volumes([]string{volumeId}, ec2.NewFilter())
		if err != nil {
			return 0, err
		}

		vol := resp.Volumes[0]

		if len(vol.Attachments) == 0 {
			return machinestate.Pending, nil
		}

		if vol.Attachments[0].Status != "attached" {
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
