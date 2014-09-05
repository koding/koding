package koding

import (
	"fmt"
	"koding/kites/kloud/klient"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

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

	resultState := infoResp.State

	p.Log.Info("[%s] info initials: current db state is '%s'. amazon ec2 state is '%s'",
		opts.MachineId, opts.State, infoResp.State)

	// corresponding states defines a map that defines a relationship from a DB
	// state to Amazon state.  That means say in DB we have the state
	// "machinestate.Building", this means the machine is in either Starting
	// mode or Terminated mode (if it was terminated before and not running
	// yet). Another example say we have the state "machinestate.Starting".
	// That means the state can be in Amazon: Starting, Running or even Stopped
	// (between the time Start is called and and info method is made.
	matchStates := map[machinestate.State][]machinestate.State{
		machinestate.Building: []machinestate.State{
			machinestate.Starting, machinestate.Terminated, machinestate.NotInitialized,
		},
		machinestate.Starting: []machinestate.State{
			machinestate.Starting, machinestate.Running, machinestate.Stopped,
		},
		machinestate.Stopping: []machinestate.State{
			machinestate.Stopping, machinestate.Stopped,
		},
		machinestate.Terminating: []machinestate.State{
			machinestate.Terminating, machinestate.Terminated,
		},
		machinestate.Stopped: []machinestate.State{
			machinestate.Stopped, machinestate.Stopping,
		},
		machinestate.Updating:   []machinestate.State{machinestate.Running},
		machinestate.Terminated: []machinestate.State{machinestate.Terminated},
	}

	// check now whether the amazon ec2 state does match one and is in
	// comparable bounds with the current state
	if infoResp.State.In(matchStates[opts.State]...) {
		p.Log.Info("[%s] info result  : db state complies with amazon state. returning current state '%s'",
			opts.MachineId, opts.State)

		// save the value in DB, this is only set if the lock is unlocked.
		// Thefore it will not change the db state if there is an ongoing
		// process.
		p.CheckAndUpdateState(opts.MachineId, infoResp.State)

		// Return the old DB state
		return &protocol.InfoArtifact{
			State: opts.State,
			Name:  infoResp.Name,
		}, nil
	}

	// we don't check if the state is something else. Klient is only available
	// when the machine is running
	if opts.State.In(machinestate.Running, machinestate.Stopped) && infoResp.State == machinestate.Running {
		resultState = opts.State

		// for the rest ask again to klient so we know if it's running or not
		machineData, ok := opts.CurrentData.(*Machine)
		if !ok {
			return nil, fmt.Errorf("current data is malformed: %v", opts.CurrentData)
		}

		p.Log.Info("[%s] amazon machine state is '%s'. pinging klient again to be sure.",
			opts.MachineId, infoResp.State)

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
				// functional so we assume it's stoped
				resultState = machinestate.Stopped
			}
		}

		p.Log.Info("[%s] info result  : fetched result from klient. returning '%s'",
			opts.MachineId, resultState)

		p.CheckAndUpdateState(opts.MachineId, resultState)

		return &protocol.InfoArtifact{
			State: resultState,
			Name:  infoResp.Name,
		}, nil

	}

	p.Log.Info("[%s] info result  : state is incosistent. correcting it to amazon state '%s'",
		opts.MachineId, infoResp.State)

	// fix the inconsistency
	p.CheckAndUpdateState(opts.MachineId, infoResp.State)

	// there is an inconsistency between the DB state and Amazon EC2 state. So
	// we are saying that the EC2 state is the correct one.
	return &protocol.InfoArtifact{
		State: infoResp.State,
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
		p.Log.Warning("[%s] can't update state because lock is acquired by someone else", id)
	}

	return err
}
