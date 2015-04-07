package koding

import (
	"fmt"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"time"

	"github.com/koding/kite"
	"golang.org/x/net/context"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func (m *Machine) Info(ctx context.Context) (map[string]string, error) {
	dbState := m.State()
	resultState := dbState
	reason := "not known yet"

	// return lazily if it's a progress state, such as "Building, Stopping,
	// etc.."
	if dbState.InProgress() {
		return map[string]string{
			"State": dbState.String(),
		}, nil
	}

	defer func() {
		// Update db state if the up-to-date state is different than the db.
		if resultState != dbState {
			m.Log.Info("Info decision: Inconsistent state between the machine and db document. Updating state to '%s'. Reason: %s",
				resultState, reason)

			if err := m.checkAndUpdateState(resultState); err != nil {
				m.Log.Debug("Info decision: Error while updating the machine state. Err: %v", m.Id, err)
			}
		}
	}()

	// Check if klient is running first.
	klientRef, err := klient.ConnectTimeout(m.Session.Kite, m.QueryString, time.Second*10)
	if err == nil {
		// we could connect to it, which is more than enough
		klientRef.Close()

		reason = "Klient is active and healthy."
		resultState = machinestate.Running

		return map[string]string{
			"State": resultState.String(),
		}, nil
	}

	if err == klient.ErrDialingFailed || err == kite.ErrNoKitesAvailable {
		// klient state is still machinestate.Unknown.
		m.Log.Debug("Klient is not registered to Kontrol. Err: %s", err)

		// XXX: AWS call reduction workaround.
		if dbState == machinestate.Stopped {
			m.Log.Debug("Info result: Returning db state '%s' because the klient is not available. Username: %s",
				dbState, m.Username)
			return map[string]string{
				"State": machinestate.Stopped.String(),
			}, nil
		}
	}

	// We couldn't reach klient, either kontrol is crashed or we couldn't dial
	// to it, and many other problems...
	reason = "Klient is not reachable."
	instance, err := m.Session.AWSClient.Instance()
	if err == nil {
		resultState = amazon.StatusToState(instance.State.Name)
	} else if err == amazon.ErrNoInstances {
		resultState = machinestate.NotInitialized
	} else {
		// if it's something else, return it back
		return nil, err
	}

	if resultState == machinestate.Unknown {
		return nil, fmt.Errorf("Unknown amazon status: %+v. This needs to be fixed.", instance.State)
	}

	// this is a case where: 1) klient is unreachable 2) machine is running
	// we don't want to give away our machines without a klient is running on it,
	// so mark and return as stopped.
	if resultState == machinestate.Running {
		resultState = machinestate.Stopped

		if m.Meta.AlwaysOn {
			// machine is always-on. return as running
			resultState = machinestate.Running
		}
	}

	// This happens when a machine was destroyed recently in one hour span.
	// The machine is still available in AWS but it's been marked as
	// Terminated. Because we still have the machine document, mark it as
	// NotInitialized so the user can build again.
	if resultState == machinestate.Terminated {
		resultState = machinestate.NotInitialized
		if err := m.markAsNotInitialized(); err != nil {
			return nil, err
		}
	}

	m.Log.Debug("Info result: '%s'. Username: %s", resultState, m.Username)
	return map[string]string{
		"State": resultState.String(),
	}, nil
}

// CheckAndUpdate state updates only if the given machine id is not used by
// anyone else
func (m *Machine) checkAndUpdateState(state machinestate.State) error {
	m.Log.Info("storage state update request to state %v", state)
	err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.Update(
			bson.M{
				"_id": m.Id,
				"assignee.inProgress": false, // only update if it's not locked by someone else
			},
			bson.M{
				"$set": bson.M{
					"status.state":      state.String(),
					"status.modifiedAt": time.Now().UTC(),
				},
			},
		)
	})

	if err == mgo.ErrNotFound {
		m.Log.Warning("info can't update db state because lock is acquired by someone else")
	}

	return err
}
