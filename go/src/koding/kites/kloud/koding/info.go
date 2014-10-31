package koding

import (
	"time"

	"github.com/koding/kite"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
)

func (p *Provider) Info(m *protocol.Machine) (result *protocol.InfoArtifact, err error) {
	// initial machine state is the state that the storage has
	dbState := m.State

	// Assume the klient state as running initially
	klientState := machinestate.Running

	// the final state that will be sent to the caller
	resultState := dbState

	// Get the klient state.
	err = klient.Exists(p.Kite, m.QueryString)
	switch err {
	case kite.ErrNoKitesAvailable:
		p.Log.Warning("[%s] Klient is disconnected, I couldn't find it through Kontrol. Err: %s",
			m.Id, err)
		klientState = machinestate.Stopped
	case nil:
	default:
		// Any other error will fallback to here. So assume that kontrol
		// failed or some other catastrophic failure occured. Thus, do not
		// stop or destroy the machine because of our failure.
		p.Log.Critical("[%s] couldn't get klient information to check the status: %s ", m.Id, err)
	}

	p.Log.Debug("[%s] Info initials: Current db state: '%s'. Klient state: '%s'",
		m.Id, dbState, klientState)

	// States are in sync. Don't do anything and return early.
	if klientState == dbState {
		return &protocol.InfoArtifact{
			State: resultState,
		}, nil
	}

	// Machine states are in inconsistent state. Find out the correct state and sync them.
	reason := ""
	switch klientState {
	case machinestate.Running:

		// If the klient is running, then it is safe to say that the  machine
		// is healthy.
		reason = "Klient is active and healthy."
		resultState = machinestate.Running
		dbState = machinestate.Running

		// Stop the shutdown timer if there is any.
		p.stopTimer(m)

	case machinestate.Stopped:
		reason = "Klient is not active."

		// Start the shutdown timer since the klient is unreachable.
		// startTimer does not turn-off always-on machines, which is good
		p.startTimer(m)

		resultState = machinestate.Stopped
		dbState = machinestate.Stopped

		// don't mark always-on machines as stopped. ever.
		if a, ok := m.Builder["alwaysOn"]; ok {
			if isAlwaysOn, ok := a.(bool); ok && isAlwaysOn {
				resultState = machinestate.Running
				dbState = machinestate.Running
				p.Log.Critical("[%s] Couldn't get klient information from an always-on machine. Treating it as in Running state", m.Id)
			}
		}
	default:
		reason = "Klient is in unknown state."
	}

	// auto-fix db state if the klient state is different than db state. This will
	// not break existing actions like building, starting, stopping etc...
	// because CheckAndUpdateState only update the state if there is no lock
	// available.
	p.Log.Info("[%s] Info decision: Inconsistent state between klient and db. Updating state to '%s'. Reason: %s", m.Id, dbState, reason)
	err = p.CheckAndUpdateState(m.Id, reason, dbState)
	if err != nil {
		p.Log.Debug("[%s] Info decision: Error while updating the machine state. Err: %v", m.Id, err)
	}

	p.Log.Debug("[%s] Info result: '%s' username: %s", m.Id, resultState, m.Username)

	return &protocol.InfoArtifact{
		State: resultState,
	}, nil

}

// CheckAndUpdate state updates only if the given machine id is not used by
// anyone else
func (p *Provider) CheckAndUpdateState(id, reason string, state machinestate.State) error {
	p.Log.Info("[%s] storage state update request to state %v", id, state)
	err := p.Session.Run("jMachines", func(c *mgo.Collection) error {
		return c.Update(
			bson.M{
				"_id": bson.ObjectIdHex(id),
				"assignee.inProgress": false, // only update if it's not locked by someone else
			},
			bson.M{
				"$set": bson.M{
					"status.state":      state.String(),
					"status.modifiedAt": time.Now().UTC(),
					"status.reason":     reason,
				},
			},
		)
	})

	if err == mgo.ErrNotFound {
		p.Log.Warning("[%s] info can't update db state because lock is acquired by someone else", id)
	}

	return err
}
