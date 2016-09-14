package vagrant

import (
	"errors"
	"time"

	"github.com/koding/kite"

	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"

	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

func (m *Machine) Stop(ctx context.Context) error {
	err := m.stop(ctx)
	if err != nil {
		return stack.NewEventerError(err)
	}

	return nil
}

func (m *Machine) stop(ctx context.Context) (err error) {
	origState := m.State()

	if err = m.updateState(machinestate.Stopping); err != nil {
		return err
	}

	if !origState.In(machinestate.Stopping, machinestate.Stopped) {
		err = m.Vagrant.Halt(m.Cred.QueryString, m.Meta.FilePath)
		if err == kite.ErrNoKitesAvailable || err == klient.ErrDialingFailed {
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
