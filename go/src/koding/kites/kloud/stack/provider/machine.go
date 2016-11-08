package provider

import (
	"fmt"
	"net"
	"net/url"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/utils/object"

	"golang.org/x/net/context"
	"gopkg.in/mgo.v2/bson"
)

func (bm *BaseMachine) HandleStart(ctx context.Context) error {
	origState := bm.State()
	currentState := origState

	bm.PushEvent("Checking machine state", 10, machinestate.Starting)

	realState, meta, err := bm.machine.Info(ctx)
	if err != nil {
		return err
	}

	defer func() {
		bm.Log.Debug("exit: origState=%s, currentState=%s, err=%v", origState, currentState, err)

		if err != nil && origState != currentState {
			modelhelper.ChangeMachineState(bm.ObjectId, "Machine is marked as "+origState.String(), origState)
		}
	}()

	bm.Log.Debug("origState=%s, currentState=%s, realState=%s", origState, currentState, realState)

	if !realState.In(machinestate.Running, machinestate.Starting) {
		currentState = machinestate.Starting

		bm.PushEvent("Starting machine", 25, currentState)

		err = modelhelper.ChangeMachineState(bm.ObjectId, "Machine is starting", currentState)
		if err != nil {
			return err
		}

		meta, err = bm.machine.Start(ctx)
		if err != nil {
			return stack.NewEventerError(err)
		}
	}

	bm.PushEvent("Checking remote machine", 75, currentState)

	dialState, err := bm.WaitKlientReady(0)
	if err != nil {
		bm.Log.Debug("waiting for klient failed with error: %s", err)

		currentState = machinestate.Stopped

		return stack.NewEventerError(err)
	}

	currentState = machinestate.Running

	if err := bm.updateMachine(dialState, meta, currentState); err != nil {
		return fmt.Errorf("failed to update machine: %s", err)
	}

	return nil
}

func (bm *BaseMachine) HandleStop(ctx context.Context) error {
	origState := bm.State()
	currentState := origState

	bm.PushEvent("Checking machine state", 10, machinestate.Stopping)

	realState, meta, err := bm.machine.Info(ctx)
	if err != nil {
		return err
	}

	defer func() {
		bm.Log.Debug("stop exit: origState=%s, currentState=%s, err=%v", origState, currentState, err)

		if err != nil && origState != currentState {
			modelhelper.ChangeMachineState(bm.ObjectId, "Machine is marked as "+origState.String(), origState)
		}
	}()

	bm.Log.Debug("stop origState=%s, currentState=%s, realState=%s", origState, currentState, realState)

	if !realState.In(machinestate.Stopping, machinestate.Stopped) {
		currentState = machinestate.Stopping

		bm.PushEvent("Stopping machine", 25, currentState)

		err = modelhelper.ChangeMachineState(bm.ObjectId, "Machine is stopping", currentState)
		if err != nil {
			return err
		}

		meta, err = bm.machine.Stop(ctx)
		if err != nil {
			return stack.NewEventerError(err)
		}

		currentState = machinestate.Stopped
	}

	if err := bm.updateMachine(nil, meta, currentState); err != nil {
		return fmt.Errorf("failed to update machine: %s", err)
	}

	return nil
}

func (bm *BaseMachine) HandleInfo(ctx context.Context) (*stack.InfoResponse, error) {
	var state *DialState

	origState := bm.State()

	currentState, meta, err := bm.machine.Info(ctx)
	if err != nil {
		return nil, err
	}

	defer func() {
		if currentState == origState {
			currentState = 0
		}

		if meta != nil || state != nil {
			bm.updateMachine(state, meta, currentState)
		} else if currentState != 0 {
			modelhelper.ChangeMachineState(bm.ObjectId, "Machine is marked as "+currentState.String(), currentState)
		}
	}()

	bm.Log.Debug("origState=%s, currentState=%s", origState, currentState)
	if currentState.InProgress() {
		return &stack.InfoResponse{
			State: currentState,
		}, nil
	}

	if origState == currentState && currentState != machinestate.Running {
		return &stack.InfoResponse{
			State: origState,
		}, nil
	}

	if alwaysOn, ok := bm.Meta["alwaysOn"].(bool); ok && alwaysOn && currentState == machinestate.Running {
		// We do not test klient connection when machine is always-on.
		// Most likely we assume that kloud/queue is going to start/restart
		// the vm if klient connectivity fails.
		return &stack.InfoResponse{
			State: currentState,
		}, nil
	}

	if state, err = bm.WaitKlientReady(10 * time.Second); err == nil {
		currentState = machinestate.Running
	} else {
		bm.Log.Debug("klient connection test failed %q: %s", bm.Label, err)
	}

	return &stack.InfoResponse{
		State: currentState,
	}, nil
}

func (bm *BaseMachine) updateMachine(state *DialState, meta interface{}, dbState machinestate.State) error {
	obj := object.MetaBuilder.Build(meta)

	if state != nil && state.KiteURL != "" {
		if bm.RegisterURL != state.KiteURL {
			obj["registerUrl"] = state.KiteURL
		}

		if u, err := url.Parse(state.KiteURL); err == nil && u.Host != "" {
			if host, _, err := net.SplitHostPort(u.Host); err == nil {
				u.Host = host
			}

			if bm.IpAddress != u.Host {
				// TODO(rjeczalik): when path routing is added (#9021) either we
				// change the ipAddress field to more generic endpoint field,
				// or we use here state.KiteURL directly.
				obj["ipAddress"] = u.Host
			}
		}
	}

	if dbState != 0 {
		obj["status.modifiedAt"] = time.Now().UTC()
		obj["status.state"] = dbState.String()
		obj["status.reason"] = "Machine is " + dbState.String()
	}

	if len(obj) == 0 {
		return nil
	}

	bm.Log.Debug("update object for %q: %+v (%# v)", bm.Label, obj, state)

	return modelhelper.UpdateMachine(bm.ObjectId, bson.M{"$set": obj})
}
