package oldkoding

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
func (p *Provider) Info(m *protocol.Machine) (*protocol.InfoArtifact, error) {
	dbState := m.State
	resultState := dbState
	reason := "not known yet"

	// return lazily if it's a progress state, such as "Building, Stopping,
	// etc.."
	if dbState.InProgress() {
		return &protocol.InfoArtifact{
			State: dbState,
		}, nil
	}

	defer func() {
		// Update db state if the up-to-date state is different than the db.
		if resultState != dbState {
			p.Log.Info("[%s] Info decision: Inconsistent state between the machine and db document. Updating state to '%s'. Reason: %s",
				m.Id, resultState, reason)

			if err := p.CheckAndUpdateState(m.Id, resultState); err != nil {
				p.Log.Debug("[%s] Info decision: Error while updating the machine state. Err: %v", m.Id, err)
			}
		}
	}()

	// Check if klient is running first.
	klientRef, err := klient.ConnectTimeout(p.Kite, m.QueryString, time.Second*10)
	if err == nil {
		// we could connect to it, which is more than enough
		p.stopTimer(m)
		klientRef.Close()

		reason = "Klient is active and healthy."
		resultState = machinestate.Running

		return &protocol.InfoArtifact{
			State: resultState,
		}, nil
	}

	if err == klient.ErrDialingFailed || err == kite.ErrNoKitesAvailable {
		// klient state is still machinestate.Unknown.
		p.Log.Debug("[%s] Klient is not registered to Kontrol. Err: %s", m.Id, err)

		// XXX: AWS call reduction workaround.
		if dbState == machinestate.Stopped {
			p.Log.Debug("[%s] Info result: Returning db state '%s' because the klient is not available. Username: %s",
				m.Id, dbState, m.Username)
			return &protocol.InfoArtifact{
				State: machinestate.Stopped,
			}, nil
		}
	}

	// We couldn't reach klient, either kontrol is crashed or we couldn't dial
	// to it, and many other problems...
	reason = "Klient is not reachable."
	amz, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}
	infoResp, err := amz.Info()
	if err != nil {
		return nil, err
	}

	resultState = infoResp.State

	// this is a case where: 1) klient is unreachable 2) machine is running
	// we don't want to give away our machines without a klient is running on it,
	// so mark and return as stopped.
	if infoResp.State == machinestate.Running {
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
