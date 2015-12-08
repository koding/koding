package softlayer

import (
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

func (m *Machine) Reinit(ctx context.Context) (err error) {
	if err := modelhelper.ChangeMachineState(m.ObjectId, "Machine is starting", machinestate.Starting); err != nil {
		return err
	}

	// update the state to intiial state if something goes wrong, we are going
	// to change latestate to a more safe state if we passed a certain step
	// below
	latestState := m.State()
	defer func() {
		if err != nil {
			modelhelper.ChangeMachineState(m.ObjectId, "Machine is marked as "+latestState.String(), latestState)
		}
	}()

	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

	// go and terminate the old instance, we don't need to wait for it
	//Get the SoftLayer virtual guest service
	svc, err := m.Session.SLClient.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		return err
	}

	_, err = svc.DeleteObject(meta.Id)
	if err != nil {
		return err
	}

	// cleanup this too so "build" can continue with a clean setup
	m.IpAddress = ""
	m.QueryString = ""
	m.Meta["id"] = 0
	m.Status.State = machinestate.NotInitialized.String()

	// this updates/creates domain
	return m.Build(ctx)
}
