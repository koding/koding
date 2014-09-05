package koding

import (
	"fmt"
	"koding/kites/kloud/klient"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/koding/kloud"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
)

func (p *Provider) Info(opts *protocol.Machine) (result *protocol.InfoArtifact, err error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	// otherwise ask AWS to get an machine state
	infoResp, err := a.Info()
	if err != nil {
		return nil, err
	}

	p.Log.Info("[%s] info initials: current db state is '%s'. amazon ec2 state is '%s'",
		opts.MachineId, dbState, awsState)

	dbState := opts.State
	awsState := infoResp.State

	// result state is the final state that is send back to the request
	resultState := dbState

	// we don't check if the state is something else. Klient is only available
	// when the machine is running
	klientChecked := false
	if dbState.In(machinestate.Running, machinestate.Stopped) && awsState == machinestate.Running {
		klientChecked = true
		// for the rest ask again to klient so we know if it's running or not
		machineData, ok := opts.CurrentData.(*Machine)
		if !ok {
			return nil, fmt.Errorf("current data is malformed: %v", opts.CurrentData)
		}

		klientRef, err := klient.NewWithTimeout(p.Kite, machineData.QueryString, time.Second*5)
		if err != nil {
			p.Log.Warning("[%s] state is '%s' but I can't connect to klient.",
				opts.MachineId, resultState)
			resultState = machinestate.Stopped
		} else {
			defer klientRef.Close()

			// now assume it's running
			resultState = machinestate.Running

			// ping the klient again just to see if it can respond to us
			if err := klientRef.Ping(); err != nil {
				p.Log.Warning("[%s] state is '%s' but I can't send a ping. Err: %s",
					opts.MachineId, resultState, err.Error())

				// seems we can't send even a simple ping! It's not
				// functional so we assume it's stopped
				resultState = machinestate.Stopped
			}
		}

		if resultState != dbState {
			// return an error anything here if the DB is locked.
			if err := p.CheckAndUpdateState(opts.MachineId, resultState); err == mgo.ErrNotFound {
				return nil, kloud.ErrLockAcquired
			}
		}

		p.Log.Info("[%s] info decision: based on klient interaction: '%s'",
			opts.MachineId, resultState)
	}

	// fix db state if the aws state is different than dbState. This will not
	// break existing actions like building,starting,stopping etc.. because
	// CheckAndUpdateState only update the state if there is no lock available
	if dbState != awsState && !klientChecked {
		// this is only set if the lock is unlocked. Thefore it will not
		// change the db state if there is an ongoing process. If there is no
		// error than it means there is no lock so we could update it with the
		// state from amazon. Therefore send it back!
		err := p.CheckAndUpdateState(opts.MachineId, awsState)
		if err == nil {
			p.Log.Info("[%s] info decision : inconsistent state. using amazon state '%s'",
				opts.MachineId, awsState)
			resultState = awsState
		}
	}

	p.Log.Info("[%s] info result   : '%s'", opts.MachineId, resultState)

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
