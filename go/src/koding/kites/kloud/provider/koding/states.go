package koding

import (
	"fmt"
	"koding/kites/kloud/machinestate"
	"time"

	"golang.org/x/net/context"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type methodFunc func(context.Context) error

// DeleteDocument deletes the associated MongoDB document.
func (m *Machine) DeleteDocument() error {
	m.Log.Debug("Deleting machine document")
	err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.RemoveId(m.Id)
	})

	if err != nil {
		return fmt.Errorf("Couldn't delete document with id: %s err: %s", m.Id.Hex(), err)
	}

	return nil
}

func (m *Machine) UpdateState(reason string, state machinestate.State) error {
	m.Log.Debug("Updating state to '%v'", state)
	err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.Update(
			bson.M{
				"_id": m.Id,
			},
			bson.M{
				"$set": bson.M{
					"status.state":      state.String(),
					"status.modifiedAt": time.Now().UTC(),
					"status.reason":     reason,
				},
			},
		)
	})

	if err != nil {
		return fmt.Errorf("Couldn't update state to '%s' for document: '%s' err: %s",
			state, m.Id.Hex(), err)
	}

	return nil
}

// switchAWSRegion switches to the given AWS region. This should be only used when
// you know what to do, otherwiese never, never change the region of a machine.
func (m *Machine) switchAWSRegion(region string) error {
	m.Meta.InstanceId = "" // we neglect any previous instanceId
	m.QueryString = ""     //
	m.Meta.Region = "us-east-1"

	client, err := m.Session.AWSClients.Region("us-east-1")
	if err != nil {
		return err
	}
	m.Session.AWSClient.Client = client

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.Id,
			bson.M{"$set": bson.M{
				"meta.instanceId": "",
				"queryString":     "",
				"meta.region":     "us-east-1",
			}},
		)
	})
}

// methodIn checks if the method exist in the given methods
func methodIn(method string, methods ...string) bool {
	for _, m := range methods {
		if method == m {
			return true
		}
	}
	return false
}
