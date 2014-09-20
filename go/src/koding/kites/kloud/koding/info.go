package koding

import (
	"koding/kites/kloud/klient"
	"sync"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
)

// invalidChanges is a list of exceptions that applies when we fix the DB state
// with the state coming from Amazon. For example if the db state is "stopped"
// there is no need to change it with the Amazon state "stopping"
var invalidChanges = map[machinestate.State]machinestate.State{
	machinestate.Stopped:    machinestate.Stopping,
	machinestate.Running:    machinestate.Starting,
	machinestate.Terminated: machinestate.Terminating,
}

// protects invalidChanges
var rwLock sync.RWMutex

// validChange returns true if the given db state is a valid to change with the
// aws state
func validChange(db, aws machinestate.State) bool {
	rwLock.Lock()
	defer rwLock.Unlock()

	return invalidChanges[db] != aws
}

func (p *Provider) Info(m *protocol.Machine) (result *protocol.InfoArtifact, err error) {
	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	// otherwise ask AWS to get an machine state
	infoResp, err := a.Info()
	if err != nil {
		return nil, err
	}

	dbState := m.State
	awsState := infoResp.State

	// result state is the final state that is send back to the request
	resultState := dbState

	p.Log.Info("[%s] info initials: current db state is '%s'. amazon ec2 state is '%s'",
		m.Id, dbState, awsState)

	// we don't check if the state is something else. Klient is only available
	// when the machine is running
	klientChecked := false
	if dbState.In(machinestate.Running, machinestate.Stopped) && awsState == machinestate.Running {
		klientChecked = true
		klientRef, err := klient.NewWithTimeout(p.Kite, m.QueryString, time.Second*5)
		if err != nil {
			p.Log.Warning("[%s] state is '%s' but I can't connect to klient.",
				m.Id, resultState)
			resultState = machinestate.Stopped
		} else {
			defer klientRef.Close()

			// now assume it's running
			resultState = machinestate.Running

			// ping the klient again just to see if it can respond to us
			if err := klientRef.Ping(); err != nil {
				p.Log.Warning("[%s] state is '%s' but I can't send a ping. Err: %s",
					m.Id, resultState, err.Error())

				// seems we can't send even a simple ping! It's not
				// functional so we assume it's stopped
				resultState = machinestate.Stopped
			}
		}

		if resultState != dbState {
			// return an error anything here if the DB is locked.
			if err := p.CheckAndUpdateState(m.Id, resultState); err == mgo.ErrNotFound {
				return nil, kloud.ErrLockAcquired
			}
		}

		p.Log.Info("[%s] info decision: based on klient interaction: '%s'",
			m.Id, resultState)
	}

	// fix db state if the aws state is different than dbState. This will not
	// break existing actions like building,starting,stopping etc.. because
	// CheckAndUpdateState only update the state if there is no lock available.
	// however only fix when it's there was no klient checking and the state
	// changing is a valid transformation (for example prevent if it's
	// "Stopped" -> "Stopping"
	if dbState != awsState && !klientChecked && validChange(dbState, awsState) {
		// this is only set if the lock is unlocked. Thefore it will not
		// change the db state if there is an ongoing process. If there is no
		// error than it means there is no lock so we could update it with the
		// state from amazon. Therefore send it back!
		err := p.CheckAndUpdateState(m.Id, awsState)
		if err == nil {
			p.Log.Info("[%s] info decision : inconsistent state. using amazon state '%s'",
				m.Id, awsState)
			resultState = awsState
		}
	}

	p.Log.Info("[%s] info result   : '%s'", m.Id, resultState)

	return &protocol.InfoArtifact{
		State: resultState,
		Name:  infoResp.Name,
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
