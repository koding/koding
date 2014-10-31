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
	dbState := m.State
	// Assume klient state as running. We're gonna change it after a few
	// checks.
	klientState := machinestate.Running

	err = klient.Exists(p.Kite, m.QueryString)
	switch err {
	case kite.ErrNoKitesAvailable:
		p.Log.Warning("[%s] klient is disconnected, I couldn't find it trough Kontrol. err: %s",
			m.Id, err)

		klientState = machinestate.Stopped

		// start shutdown timer, because klient is not running, don't let
		// it be running forever
		p.startTimer(m)
	case nil:
		// klient is running and there is no error. We are stopping the timer
		// because everything seems cool.
		p.stopTimer(m)
	default:
		// Any other error will fallback to here. So assume that kontrol
		// failed or some other catastrophic reason. So do not stop or destroy
		// the machine because of our failure.
		p.stopTimer(m)
		// error is something else and critical, so don't do anything until it's resolved
		p.Log.Critical("[%s] couldn't get klient information to check the status: %s ", m.Id, err)
	}

	// result state is the final state that is send back to the request
	resultState := dbState

	p.Log.Info("[%s] info initials: current db state is '%s'. klient state is '%s'",
		m.Id, dbState, klientState)

	// auto-fix db state if the klient state is different than dbState. This will
	// not break existing actions like building, starting, stopping etc...
	// because CheckAndUpdateState only update the state if there is no lock
	// available.
	if dbState != klientState && dbState.In(machinestate.Running, machinestate.Stopped) {
		reason := ""
		switch klientState {
		case machinestate.Running:
			reason = "Klient is active and healthy."
		case machinestate.Stopped:
			reason = "Klient is not active."
		default:
			reason = "Klient is in unknown state."
		}

		// return an error anything here if the DB is locked.
		err := p.CheckAndUpdateState(m.Id, reason, klientState)
		if err == nil {
			p.Log.Info("[%s] info decision : inconsistent state. using klient state '%s'",
				m.Id, klientState)
			// return klientState since it is the most updated one.
			resultState = klientState
		} else {
			p.Log.Info("[%s] info decision : using current db state '%s'",
				m.Id, resultState)
		}
	}

	p.Log.Info("[%s] info result: '%s' username: %s", m.Id, resultState, m.Username)

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
