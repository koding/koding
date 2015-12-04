package softlayer

import (
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

// Stop stops the given machine
func (m *Machine) Stop(ctx context.Context) error {
	if err := modelhelper.ChangeMachineState(m.ObjectId, "Machine is stopping", machinestate.Stopping); err != nil {
		return err
	}

	//Get the SoftLayer virtual guest service
	svc, err := m.Session.SLClient.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		return err
	}

	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

	_, err = svc.PowerOff(meta.Id)
	if err != nil {
		return err
	}

	if err := waitState(svc, meta.Id, "HALTED"); err != nil {
		return err
	}

	if err := m.deleteDomains(); err != nil {
		m.Log.Warning("couldn't delete domains while stopping machine: %s", err)
	}

	return m.MarkAsStoppedWithReason("Machine is stopped")
}

func (m *Machine) deleteDomains() error {
	m.push("Initializing domain instance", 65, machinestate.Stopping)
	if err := m.Session.DNSClient.Validate(m.Domain, m.Username); err != nil {
		return err
	}

	m.push("Changing domain to sleeping mode", 85, machinestate.Stopping)
	if err := m.Session.DNSClient.Delete(m.Domain); err != nil {
		m.Log.Warning("couldn't delete domain %s", err)
	}

	// also get all domain aliases that belongs to this machine and unset
	domains, err := m.Session.DNSStorage.GetByMachine(m.ObjectId.Hex())
	if err != nil {
		m.Log.Error("fetching domains for unseting err: %s", err.Error())
	}

	for _, domain := range domains {
		if err := m.Session.DNSClient.Delete(domain.Name); err != nil {
			m.Log.Warning("couldn't delete domain %s", err)
		}
	}

	return nil
}
