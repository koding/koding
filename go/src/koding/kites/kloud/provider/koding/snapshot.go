package koding

import (
	"errors"
	"fmt"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
)

func (p *Provider) CreateSnapshot(m *protocol.Machine) error {
	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	instance, err := a.Instance(a.Id())
	if err != nil {
		return err
	}

	if len(instance.BlockDevices) == 0 {
		return fmt.Errorf("createSnapshot: no block device available")
	}

	if m.State != machinestate.Stopped {
		a.Log.Debug("[%s] Stopping machine for creating snapshot", m.Id)
		if err := a.Stop(false); err != nil {
			return err
		}
	}

	volumeId := instance.BlockDevices[0].VolumeId
	snapshotDesc := fmt.Sprintf("user-%s-%s", m.Username, m.Id)

	a.Log.Debug("[%s] Creating snapshot '%s'", m.Id, snapshotDesc)
	snapshot, err := a.CreateSnapshot(volumeId, snapshotDesc)
	if err != nil {
		return err
	}

	a.Log.Debug("[%s] Snapshot created successfully: %+v", m.Id, snapshot)

	return errors.New("createSnapshot is not implemented yet.")
}
