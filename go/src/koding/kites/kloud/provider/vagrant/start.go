package vagrant

import (
	"errors"
	"time"

	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

func (m *Machine) Start(ctx context.Context) error {
	// Since vagrant up builds also the machine, start it only
	// when its state is effectively stopped.
	return m.start(machinestate.Stopped, machinestate.Stopping)
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
		if err = m.markAsNotInitialized(); err != nil {
			return err
		}

		return errors.New("box is not available anymore")
	}
	if err != nil {
		return err
	}

	m.push("Starting machine", 25, machinestate.Starting)

	if origState.In(states...) {
		if err = m.api.Up(m.Meta.HostQueryString, m.Meta.FilePath); err != nil {
			return err
		}
	}

	m.push("Checking remote machine", 75, machinestate.Starting)

	if !m.waitKlientReady() {
		return errors.New("klient is not ready")
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
