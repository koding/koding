package awsprovider

import (
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/machinestate"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"
)

func (m *Machine) Stop(ctx context.Context) (err error) {
	if err := modelhelper.ChangeMachineState(m.Id, "Machine is stopping", machinestate.Stopping); err != nil {
		return err
	}

	// update the state to intiial state if something goes wrong, we are going
	// to change latestate to a more safe state if we passed a certain step
	// below
	latestState := m.State()
	defer func() {
		if err != nil {
			modelhelper.ChangeMachineState(m.Id, "Machine is marked as "+latestState.String(), latestState)
		}
	}()

	err = m.Session.AWSClient.Stop(ctx)
	if err != nil {
		return err
	}

	latestState = machinestate.Stopped

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.Id,
			bson.M{"$set": bson.M{
				"ipAddress":         "",
				"status.state":      machinestate.Stopped.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Machine is stopped",
			}},
		)
	})
}
