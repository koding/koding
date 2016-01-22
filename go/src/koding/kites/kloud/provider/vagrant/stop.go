package vagrant

import (
	"time"

	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

func (m *Machine) Stop(ctx context.Context) (err error) {
	origState := m.State()

	if err = m.updateState(machinestate.Stopping); err != nil {
		return err
	}

	if !origState.In(machinestate.Stopping, machinestate.Stopped) {
		if err = m.api.Halt(m.Meta.HostQueryString, m.Meta.FilePath); err != nil {
			m.updateState(origState) // bring back original state
			return err
		}
	}

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"ipAddress":         "",
				"status.state":      machinestate.Stopped.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Machine is stopped",
			}},
		)
	})
}
