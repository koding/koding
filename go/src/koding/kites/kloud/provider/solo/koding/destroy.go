package koding

import (
	"fmt"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/machinestate"

	"gopkg.in/mgo.v2"

	"golang.org/x/net/context"
)

// Destroy implements the Destroyer interface. It uses destroyMachine(ctx)
// function but updates/deletes the MongoDB document once finished.
func (m *Machine) Destroy(ctx context.Context) (err error) {
	if err := m.UpdateState("Machine is termating", machinestate.Terminating); err != nil {
		return err
	}

	// update the state to intiial state if something goes wrong, we are going
	// to change latestate to a more safe state if we passed a certain step
	// below
	latestState := m.State()
	defer func() {
		if err != nil {
			m.UpdateState("Machine is marked as "+latestState.String(), latestState)
		}
	}()

	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

	// try to destroy the instance, however if the instance is not available
	// anymore just continue.
	if meta.InstanceId != "" {
		m.Log.Debug("Destroying machine")
		err := m.Session.AWSClient.Destroy(ctx, 10, 50)
		if err != nil && !amazon.IsNotFound(err) {
			// if it's something else return it
			return err
		}
	}

	m.Log.Debug("Removing attached domains")
	m.push("Deleting base domain", 85, machinestate.Terminating)
	if err := m.Session.DNSClient.Delete(m.Domain); err != nil {
		// if it's already deleted, for example because of a STOP, than we just
		// log it here instead of returning the error
		m.Log.Error("deleting domain during destroying err: %s", err)
	}

	domains, err := m.Session.DNSStorage.GetByMachine(m.ObjectId.Hex())
	if err != nil {
		m.Log.Error("fetching domains for unsetting err: %s", err)
	}

	m.push("Deleting custom domain", 90, machinestate.Terminating)
	for _, domain := range domains {
		if err := m.Session.DNSClient.Delete(domain.Name); err != nil {
			m.Log.Error("couldn't delete domain: %s", err)
		}

		err := m.Session.DNSStorage.UpdateMachine(domain.Name, "")
		if err != nil {
			m.Log.Error("couldn't unset machine domain: %s", err)
		}
	}

	m.releaseEIP()

	// clean up these details, the instance doesn't exist anymore
	m.Meta["instanceName"] = ""
	m.Meta["instanceId"] = ""
	m.IpAddress = ""
	m.QueryString = ""

	return m.DeleteDocument()
}

// DeleteDocument deletes the associated MongoDB document.
func (m *Machine) DeleteDocument() error {
	m.Log.Debug("Deleting machine document")
	err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.RemoveId(m.ObjectId)
	})

	if err != nil {
		return fmt.Errorf("Couldn't delete document with id: %s err: %s", m.ObjectId.Hex(), err)
	}

	return nil
}
