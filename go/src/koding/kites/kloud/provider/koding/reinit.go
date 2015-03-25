package koding

import (
	"koding/kites/kloud/machinestate"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"
)

func (m *Machine) Reinit(ctx context.Context) error {
	if err := m.UpdateState("Machine is starting", machinestate.Starting); err != nil {
		return err
	}

	if err := m.Session.AWSClient.Destroy(ctx, 10, 50); err != nil {
		return err
	}

	// clean up old data, so if build fails below at least we give the chance to build it again
	err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.Id,
			bson.M{"$set": bson.M{
				"ipAddress":         "",
				"meta.instanceId":   "",
				"meta.instanceName": "",
				"queryString":       "",
				"status.state":      machinestate.NotInitialized.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Reinit cleanup",
			}},
		)
	})
	if err != nil {
		return err
	}

	// cleanup this too so "build" can continue with a clean setup
	m.Meta.InstanceId = ""
	m.Meta.InstanceName = ""
	m.IpAddress = ""
	m.QueryString = ""

	// this updates/creates domain
	return m.Build(ctx)
}
