package vagrant

import (
	"errors"
	"time"

	"github.com/koding/kite"

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
		err = m.api.Halt(m.Meta.HostQueryString, m.Meta.FilePath)
		if err == kite.ErrNoKitesAvailable {
			m.updateState(origState)
			return errors.New("unable to connect to host klient, is it down?")
		}

		if err != nil {
			m.updateState(origState)
			return err
		}
	}

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"status.state":      machinestate.Stopped.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Machine is stopped",
			}},
		)
	})
}
