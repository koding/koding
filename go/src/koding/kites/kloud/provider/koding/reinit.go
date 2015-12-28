package koding

import (
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/machinestate"
	"time"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"

	"golang.org/x/net/context"
)

func (m *Machine) Reinit(ctx context.Context) (err error) {
	if err := m.UpdateState("Machine is starting", machinestate.Building); err != nil {
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

	// try to destroy the instance, however if the instance is not available
	// anymore just continue with the build and do not return
	id := m.Session.AWSClient.Id()
	if _, err := m.Session.AWSClient.TerminateInstance(id); err != nil && !amazon.IsNotFound(err) {
		return err
	}

	// clean up old data, so if build fails below at least we give the chance to build it again
	err = m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"ipAddress":         "",
				"queryString":       "",
				"meta.instanceId":   "",
				"meta.instanceName": "",
				"status.state":      machinestate.Building.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Reinit initialized",
			}},
		)
	})
	if err != nil {
		m.Log.Warning("couldn't update reinit db: %s", err)
	}

	// cleanup this too so "build" can continue with a clean setup
	m.IpAddress = ""
	m.QueryString = ""
	m.Meta["instanceName"] = ""
	m.Meta["instanceId"] = ""
	m.Status.State = machinestate.NotInitialized.String()

	// this updates/creates domain
	return m.Build(ctx)
}
