package softlayer

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

func (m *Machine) Restart(ctx context.Context) error {
	return m.guardTransition(machinestate.Rebooting, "Machine is restarting", ctx, m.restart)
}

func (m *Machine) restart(ctx context.Context) error {
	//Get the SoftLayer virtual guest service
	svc, err := m.Session.SLClient.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		return err
	}

	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

	ok, err := svc.RebootSoft(meta.Id)
	if err != nil {
		return err
	}

	if !ok {
		m.Log.Warning("softlayer rebooting returned false instead of true")
	}

	if err := m.waitState(svc, meta.Id, "RUNNING", m.StateTimeout); err != nil {
		return err
	}

	m.push("Checking remote machine", 90, machinestate.Starting)
	if !m.IsKlientReady() {
		return errors.New("klient is not ready")
	}

	return modelhelper.ChangeMachineState(m.ObjectId, "Machine is Running", machinestate.Running)
}
