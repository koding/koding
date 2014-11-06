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

	// Assume the klient state as unknown initially
	klientState := machinestate.Unknown

	// the final state that will be sent to the caller
	var resultState machinestate.State

	// Get the klient state.
	err = klient.Exists(p.Kite, m.QueryString)
	switch err {
	case nil:
		klientState = machinestate.Running
	case kite.ErrNoKitesAvailable:
		p.Log.Warning("[%s] Klient is disconnected, I couldn't find it through Kontrol. Err: %s",
			m.Id, err)
	default:
		// Any other error will fallback to here. So assume that kontrol
		// failed or some other catastrophic failure occured. Thus, do not
		// stop or destroy the machine because of our failure.
		p.Log.Critical("[%s] couldn't get klient information to check machine status: %s ", m.Id, err)
	}

	p.Log.Debug("[%s] Info initials: Current db state: '%s'. Klient state: '%s'",
		m.Id, dbState, klientState)

	switch klientState {
	case machinestate.Running:
		p.Log.Debug("[%s] Info log: klient is running", m.Id)

		// Stop the shutdown timer if there is any.
		p.stopTimer(m)

		if dbState == machinestate.Running {
			p.Log.Debug("[%s] Info log: klient is running and dbstate is running too. Doing nothing but returning", m.Id)
			return &protocol.InfoArtifact{
				State: machinestate.Running,
			}, nil
		}
		resultState = machinestate.Running
		dbState = machinestate.Running
		p.Log.Debug("[%s] Info log: klient is running and dbstate is not running. Setting dbstate to running.", m.Id)

	case machinestate.Unknown:
		p.Log.Debug("[%s] Info log: klient is not reachable. Asking to AWS about the machine state. Also started the shutdown-timer.", m.Id)

		// Start the shutdown timer since the klient is unreachable.
		// startTimer does not turn-off always-on machines, which is good
		p.startTimer(m)

		// Since klient is not registered, we have to ask for AWS about the machine state.
		a, err := p.NewClient(m)
		if err != nil {
			return nil, err
		}
		infoResp, err := a.Info()
		if err != nil {
			return nil, err
		}

		awsState := infoResp.State

		if dbState == awsState {
			p.Log.Debug("[%s] Info log: dbState(%s) and awsState(%s) are the same. Not gonna update the db", m.Id, dbState, awsState)
			return &protocol.InfoArtifact{
				State: awsState,
			}, nil
		}

		dbState = awsState
		resultState = awsState
	}

	// auto-fix db state if the klient state is different than db state. This will
	// not break existing actions like building, starting, stopping etc...
	// because CheckAndUpdateState only update the state if there is no lock
	// available.
	p.Log.Info("[%s] Info decision: Inconsistent state between the machine and db document. Updating state to '%s'.", m.Id, dbState)
	err = p.CheckAndUpdateState(m.Id, dbState)
	if err != nil {
		p.Log.Debug("[%s] Info decision: Error while updating the machine state. Err: %v", m.Id, err)
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
