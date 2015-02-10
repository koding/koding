package koding

import (
	"fmt"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
)

func (p *Provider) CreateSnapshot(m *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	a.Push("Creating snapshot initialized", 10, machinestate.Pending)
	instance, err := a.Instance(a.Id())
	if err != nil {
		return nil, err
	}

	if len(instance.BlockDevices) == 0 {
		return nil, fmt.Errorf("createSnapshot: no block device available")
	}

	if m.State != machinestate.Stopped {
		a.Log.Debug("[%s] Stopping machine for creating snapshot", m.Id)
		if err := a.Stop(false); err != nil {
			return nil, err
		}
	}

	volumeId := instance.BlockDevices[0].VolumeId
	snapshotDesc := fmt.Sprintf("user-%s-%s", m.Username, m.Id)

	a.Log.Debug("[%s] Creating snapshot '%s'", m.Id, snapshotDesc)
	a.Push("Creating snapshot", 40, machinestate.Pending)
	snapshot, err := a.CreateSnapshot(volumeId, snapshotDesc)
	if err != nil {
		return nil, err
	}
	a.Log.Debug("[%s] Snapshot created successfully: %+v", m.Id, snapshot)

	a.Log.Debug("[%s] Starting the machine after snapshot creation", m.Id)
	a.Push("Starting instance", 70, machinestate.Pending)
	// start the stopped instance now as we attached the new volume
	artifact, err := a.Start(false)
	if err != nil {
		return nil, err
	}

	a.Push("Updating domain", 85, machinestate.Pending)
	// update Domain record with the new IP
	if err := p.UpdateDomain(artifact.IpAddress, m.Domain.Name, m.Username); err != nil {
		return nil, err
	}

	a.Push("Updating domain aliases", 87, machinestate.Pending)
	// also get all domain aliases that belongs to this machine and unset
	domains, err := p.DomainStorage.GetByMachine(m.Id)
	if err != nil {
		p.Log.Error("[%s] fetching domains for unsetting err: %s", m.Id, err.Error())
	}

	for _, domain := range domains {
		if err := p.UpdateDomain(artifact.IpAddress, domain.Name, m.Username); err != nil {
			p.Log.Error("[%s] couldn't update domain: %s", m.Id, err.Error())
		}
	}

	a.Push("Checking connectivity", 90, machinestate.Pending)
	artifact.DomainName = m.Domain.Name

	if p.IsKlientReady(m.QueryString) {
		p.Log.Debug("[%s] klient is ready.", m.Id)
	} else {
		p.Log.Warning("[%s] klient is not ready. I couldn't connect to it.", m.Id)
	}

	return artifact, nil
}
