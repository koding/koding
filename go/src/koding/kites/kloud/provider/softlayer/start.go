package softlayer

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

// Start starts the given machine
func (m *Machine) Start(ctx context.Context) error {
	if err := modelhelper.ChangeMachineState(m.Id, "Machine is starting", machinestate.Starting); err != nil {
		return err
	}

	//Get the SoftLayer virtual guest service
	svc, err := m.Session.SLClient.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		return err
	}

	_, err = svc.PowerOn(m.Meta.Id)
	if err != nil {
		return err
	}

	if err := waitState(svc, m.Meta.Id, "RUNNING"); err != nil {
		return err
	}

	m.push("Checking remote machine", 90, machinestate.Starting)
	if !m.IsKlientReady() {
		return errors.New("klient is not ready")
	}

	return modelhelper.ChangeMachineState(m.Id, "Machine is Running", machinestate.Running)
}
