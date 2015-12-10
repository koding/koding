package softlayer

import (
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

// Destroy implements the Destroyer interface. It uses destroyMachine(ctx)
// function but updates/deletes the MongoDB document once finished.
func (m *Machine) Destroy(ctx context.Context) error {
	if err := modelhelper.ChangeMachineState(m.ObjectId, "Machine is terminating",
		machinestate.Terminating); err != nil {
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

	ok, err := svc.DeleteObject(meta.Id)
	if err != nil {
		return err
	}

	if !ok {
		m.Log.Warning("softlayer destroying returned false instead of true")
	}

	if err := m.deleteDomains(); err != nil {
		m.Log.Warning("couldn't delete domains while stopping machine: %s", err)
	}

	// clean up these details, the instance doesn't exist anymore
	m.Meta["id"] = 0
	m.IpAddress = ""
	m.QueryString = ""

	return modelhelper.DeleteMachine(m.ObjectId)
}
