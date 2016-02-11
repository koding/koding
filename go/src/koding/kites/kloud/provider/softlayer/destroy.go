package softlayer

import (
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

// Destroy implements the Destroyer interface. It uses destroyMachine(ctx)
// function but updates/deletes the MongoDB document once finished.
func (m *Machine) Destroy(ctx context.Context) error {
	return m.guardTransition(machinestate.Terminating, "Machine is terminating", ctx, m.destroy)
}

func (m *Machine) destroy(ctx context.Context) error {
	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

	err = m.Session.SLClient.DeleteInstance(meta.Id)
	if err != nil && !isNotFound(err) {
		// if it's something else return it, otherwise just continue
		return err
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

// IsNotFound returns true if the error is *NotFoundError.
func isNotFound(err error) bool {
	if slErr, ok := err.(*sl.Error); ok {
		if slErr.Code == "SoftLayer_Exception_NotFound" {
			return true
		}
	}

	return false
}
