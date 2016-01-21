package vagrant

import (
	"errors"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

func toObject(s machinestate.State) map[string]string {
	return map[string]string{
		"State": s.String(),
	}
}

func (m *Machine) Info(ctx context.Context) (map[string]string, error) {
	dbState := m.State()
	resultState := dbState
	reason := "not known yet"

	if dbState.InProgress() {
		return toObject(dbState), nil
	}

	defer m.fixInconsistentState(resultState, dbState, reason)

	// Test klient connectivity, return the result of the test if:
	//
	//   - klient is up
	//   - klient is down and db state is stopped
	//
	kref, err := klient.ConnectTimeout(m.Session.Kite, m.QueryString, time.Second*10)
	switch {
	case err == nil:
		kref.Close()

		reason = "Klient is active and healthy."
		resultState = machinestate.Running

		return toObject(resultState), nil
	case err == klient.ErrDialingFailed || err == kite.ErrNoKitesAvailable:
		m.Log.Debug("Klient is not registered to Kontrol. Err: %s", err)

		if dbState == machinestate.Stopped {
			m.Log.Debug("Info result: Returning db state '%s' because the klient"+
				" is not available. Username: %s", dbState, m.User.Name)

			return toObject(machinestate.Stopped), nil
		}
	}

	reason = "Klient is not reachable"
	resultState, err = m.status()

	switch err {
	case nil: // ok
	case errNotFound:
		reason = "Machine was not found"
		resultState = machinestate.NotInitialized
	default:
		return nil, err
	}

	switch resultState {
	case machinestate.Terminating, machinestate.Terminated:
		reason = "Machine was terminated in last one hour span"
		resultState = machinestate.Terminated

		err := modelhelper.ChangeMachineState(m.ObjectId, reason, resultState)
		if err != nil {
			return nil, err
		}
	}

	return toObject(resultState), nil

}

func (m *Machine) fixInconsistentState(actual, db machinestate.State, reason string) {
	// Update db state if the up-to-date state is different than the db.
	if actual != db {
		m.Log.Info("Info decision: Inconsistent state between the machine and db document."+
			" Updating state from %q to %q. Reason: %s", db, actual, reason)

		if err := modelhelper.CheckAndUpdateState(m.ObjectId, actual); err != nil {
			m.Log.Warning("Info decision: Error while updating the machine %q state. Err: %s", m.ObjectId, err)
		}
	}
}

var errNotFound = errors.New("the box was not found")

func (m *Machine) status() (machinestate.State, error) {
	// TODO(rjeczalik): We're using list instead of status to workaround
	// TMS-2106.
	list, err := m.api.List(m.Meta.HostQueryString)
	if err != nil {
		return 0, err
	}

	for _, l := range list {
		if l.FilePath == m.Meta.FilePath {
			return l.State.MachineState(), nil
		}
	}

	return 0, errNotFound
}
