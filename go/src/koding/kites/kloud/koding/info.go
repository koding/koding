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

// Info checks the machine state based on the klient and AWS states.
func (p *Provider) Info(m *protocol.Machine) (result *protocol.InfoArtifact, err error) {

	dbState := m.State
	resultState := dbState
	klientState := machinestate.Unknown

	// Check if klient is running first.
	klientRef, err := klient.Connect(p.Kite, m.QueryString)
	switch err {
	case nil:
		if err = klientRef.Ping(); err != nil {
			p.Log.Info("[%s] Klient is not responding to 'ping' request. Err: %v", m.Id, err)
		}
		klientRef.Close()
		klientState = machinestate.Running
	case kite.ErrNoKitesAvailable:
		// klient state is still machinestate.Unknown.
		p.Log.Debug("[%s] Klient is not registered to Kontrol. Err: %s", m.Id, err)
	case klient.ErrDialingKlientFailed:
		// klient state is still machinestate.Unknown.
		p.Log.Debug("[%s] %s", m.Id, err)
	default:
		// Any other error will fallback to here. So assume that kontrol
		// failed or some other catastrophic failure occured. So, do not
		// stop or destroy the machine because of our failure.
		klientState = machinestate.Running
		p.Log.Critical("[%s] couldn't get klient information to check machine status. Probably couldn't connect to Kontrol. Err: %s ", m.Id, err)
	}

	reason := ""
	switch klientState {
	case machinestate.Running:
		reason = "Klient is active and healthy."

		p.stopTimer(m)
		resultState = machinestate.Running
	case machinestate.Unknown:
		reason = "Klient is not reachable."

		amz, err := p.NewClient(m)
		if err != nil {
			return nil, err
		}
		infoResp, err := amz.Info()
		if err != nil {
			return nil, err
		}

		switch infoResp.State {
		case machinestate.Running:
			// this is a case where: 1) klient is unreachable 2) machine is running
			// we don't want to give away our machines without a klient is running on it,
			// so mark and return as stopped.
			resultState = machinestate.Stopped

			// startTimer does not start a timer on always-on machines. no worries.
			p.startTimer(m)

			// Check if the machine is always-on and don't send a stopped state.
			if a, ok := m.Builder["alwaysOn"]; ok {
				if isAlwaysOn, ok := a.(bool); ok && isAlwaysOn {
					// machine is always-on. return as running
					resultState = machinestate.Running
				}
			}
		default:
			// This is the place where a state transition is in place or simply
			// the machine is stopped/terminated. So we don't expect the klient
			// to be run. Return as is.
			resultState = infoResp.State
		}
	}

	// Update db state if the up-to-date state is different than the db.
	if resultState != dbState {
		p.Log.Info("[%s] Info decision: Inconsistent state between the machine and db document. Updating state to '%s'. Reason: %s", m.Id, resultState, reason)
		err = p.CheckAndUpdateState(m.Id, resultState)
		if err != nil {
			p.Log.Debug("[%s] Info decision: Error while updating the machine state. Err: %v", m.Id, err)
		}

	}

	p.Log.Debug("[%s] Info result: '%s'. Username: %s", m.Id, resultState, m.Username)
	return &protocol.InfoArtifact{
		State: resultState,
	}, nil
}

// CheckAndUpdate state updates only if the given machine id is not used by
// anyone else
func (p *Provider) CheckAndUpdateState(id string, state machinestate.State) error {
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
				},
			},
		)
	})

	if err == mgo.ErrNotFound {
		p.Log.Warning("[%s] info can't update db state because lock is acquired by someone else", id)
	}

	return err
}
