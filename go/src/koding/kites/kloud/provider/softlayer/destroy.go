package softlayer

import (
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

// Destroy implements the Destroyer interface. It uses destroyMachine(ctx)
// function but updates/deletes the MongoDB document once finished.
func (m *Machine) Destroy(ctx context.Context) error {
	if err := modelhelper.ChangeMachineState(m.Id, "Machine is terminating",
		machinestate.Terminating); err != nil {
		return err
	}

	//Get the SoftLayer virtual guest service
	svc, err := m.Session.SLClient.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		return err
	}

	ok, err := svc.DeleteObject(m.Meta.Id)
	if err != nil {
		return err
	}

	if !ok {
		m.Log.Warning("softlayer destroying returned false instead of true")
	}

	// clean up these details, the instance doesn't exist anymore
	m.Meta.Id = 0
	m.IpAddress = ""
	m.QueryString = ""

	return modelhelper.DeleteMachine(m.Id)
}
