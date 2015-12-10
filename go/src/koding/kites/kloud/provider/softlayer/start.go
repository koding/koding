package softlayer

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

// Start starts the given machine
func (m *Machine) Start(ctx context.Context) error {
	if err := modelhelper.ChangeMachineState(m.ObjectId, "Machine is starting", machinestate.Starting); err != nil {
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

	_, err = svc.PowerOn(meta.Id)
	if err != nil {
		return err
	}

	if err := waitState(svc, meta.Id, "RUNNING"); err != nil {
		return err
	}

	if err := m.addDomains(); err != nil {
		m.Log.Warning("couldn't update domains during start: %s", err)
	}

	m.push("Checking remote machine", 90, machinestate.Starting)
	if !m.IsKlientReady() {
		return errors.New("klient is not ready")
	}

	return modelhelper.ChangeMachineState(m.ObjectId, "Machine is Running", machinestate.Running)
}
