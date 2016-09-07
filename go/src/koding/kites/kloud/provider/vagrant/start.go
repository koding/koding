package vagrant

import (
	"errors"
	"time"

	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"

	"github.com/koding/kite"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

func (m *Machine) Start(ctx context.Context) error {
	// Since vagrant up builds also the machine, start it only
	// when its state is effectively stopped.
	err := m.start(machinestate.Stopped, machinestate.Stopping)
	if err != nil {
		return stack.NewEventerError(err)
	}

	return nil
}

func (m *Machine) start(states ...machinestate.State) (err error) {
	origState := m.State()

	if err = m.updateState(machinestate.Starting); err != nil {
		return err
	}

	defer func() {
		if err != nil {
			// bring back original state in case of error
			m.updateState(origState)
		}
	}()

	state, err := m.status()

	if err == errNotFound || (!state.In(states...) && state.In(machinestate.Terminating, machinestate.Terminated)) {
		return errors.New("box is not available anymore")
	}
	if err != nil {
		return err
	}

	m.PushEvent("Starting machine", 25, machinestate.Starting)

	if origState.In(states...) {
		err = m.Vagrant.Up(m.Cred.QueryString, m.Meta.FilePath)
		if err == kite.ErrNoKitesAvailable || err == klient.ErrDialingFailed {
			return errors.New("unable to connect to host klient, is it down?")
		}

		if err != nil {
			return err
		}
	}

	m.PushEvent("Checking remote machine", 75, machinestate.Starting)

	if err := m.WaitKlientReady(); err != nil {
		return err
	}

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"status.state":      machinestate.Running.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Machine is running",
			}},
		)
	})
}
