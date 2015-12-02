package softlayer

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

func (m *Machine) Restart(ctx context.Context) (err error) {
	if err := modelhelper.ChangeMachineState(m.ObjectId, "Machine is restarting", machinestate.Rebooting); err != nil {
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

	ok, err := svc.RebootSoft(meta.Id)
	if err != nil {
		return err
	}

	if !ok {
		m.Log.Warning("softlayer rebooting returned false instead of true")
	}

	if err := waitState(svc, meta.Id, "RUNNING"); err != nil {
		return err
	}

	m.push("Checking remote machine", 90, machinestate.Starting)
	if !m.IsKlientReady() {
		return errors.New("klient is not ready")
	}

	return modelhelper.ChangeMachineState(m.ObjectId, "Machine is Running", machinestate.Running)
}
