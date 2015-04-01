package koding

import (
	"koding/kites/kloud/machinestate"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"
)

func (m *Machine) Restart(ctx context.Context) error {
	if err := m.UpdateState("Machine is restarting", machinestate.Rebooting); err != nil {
		return err
	}

	err := m.Session.AWSClient.Restart(ctx)
	if err != nil {
		return err
	}

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.Id,
			bson.M{"$set": bson.M{
				"status.state":      machinestate.Running.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Machine is running",
			}},
		)
	})
}
