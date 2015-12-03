package koding

import (
	"koding/kites/kloud/machinestate"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"
)

func (m *Machine) Reinit(ctx context.Context) error {
	// clean up old data, so if build fails below at least we give the chance
	// to build it again
	err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.Id,
			bson.M{"$set": bson.M{
				"ipAddress":         "",
				"queryString":       "",
				"meta.instanceId":   "",
				"meta.instanceName": "",
				"status.state":      machinestate.NotInitialized.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Reinit initalized",
			}},
		)
	})
	if err != nil {
		m.Log.Warning("couldn't update reinit db: %s", err)
	}

	// go and terminate the old instance, we don't need to wait for it
	go func(machine *Machine) {
		instanceId := machine.Session.AWSClient.Id()
		_, err := machine.Session.AWSClient.TerminateInstance(instanceId)
		if err != nil {
			m.Log.Warning("couldn't terminate instance: %s", err)
		}
	}(m)

	// cleanup this too so "build" can continue with a clean setup
	m.IpAddress = ""
	m.QueryString = ""
	m.Meta.InstanceId = ""
	m.Meta.InstanceName = ""
	m.Status.State = machinestate.NotInitialized.String()

	// this updates/creates domain
	return m.Build(ctx)
}
