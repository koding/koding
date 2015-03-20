package kloud

import (
	"fmt"
	"strings"
	"time"

	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

type ControlResult struct {
	State   machinestate.State `json:"state"`
	EventId string             `json:"eventId"`
}

type machineFunc func(context.Context, interface{}) error

type statePair struct {
	initial machinestate.State
	final   machinestate.State
}

var states = map[string]*statePair{
	"build":          &statePair{initial: machinestate.Building, final: machinestate.Running},
	"start":          &statePair{initial: machinestate.Starting, final: machinestate.Running},
	"stop":           &statePair{initial: machinestate.Stopping, final: machinestate.Stopped},
	"destroy":        &statePair{initial: machinestate.Terminating, final: machinestate.Terminated},
	"restart":        &statePair{initial: machinestate.Rebooting, final: machinestate.Running},
	"resize":         &statePair{initial: machinestate.Pending, final: machinestate.Running},
	"reinit":         &statePair{initial: machinestate.Terminating, final: machinestate.Running},
	"createSnapshot": &statePair{initial: machinestate.Snapshotting, final: machinestate.Running},
	"deleteSnapshot": &statePair{initial: machinestate.Snapshotting, final: machinestate.Running},
}

// func (k *Kloud) Start(r *kite.Request) (resp interface{}, reqErr error) {
// 	startFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
// 		resp, err := p.Start(m)
// 		if err != nil {
// 			return nil, err
// 		}
//
// 		// some providers might provide empty information, therefore do not
// 		// update anything for them
// 		if resp == nil {
// 			return resp, nil
// 		}
//
// 		err = k.Storage.Update(m.Id, &StorageData{
// 			Type: "start",
// 			Data: map[string]interface{}{
// 				"ipAddress":    resp.IpAddress,
// 				"domainName":   resp.DomainName,
// 				"instanceId":   resp.InstanceId,
// 				"instanceName": resp.InstanceName,
// 			},
// 		})
//
// 		if err != nil {
// 			k.Log.Error("[%s] updating data after start method was not possible: %s",
// 				m.Id, err.Error())
// 		}
//
// 		resultInfo := fmt.Sprintf("username: [%s], instanceId: [%s], ipAdress: [%s]",
// 			r.Username, resp.InstanceId, resp.IpAddress)
//
// 		k.Log.Info("[%s] ========== START results ========== %s",
// 			m.Id, resultInfo)
//
// 		// do not return the error, the machine is already prepared and
// 		// started, it should be ready
// 		return resp, nil
// 	}
//
// 	return k.coreMethods(r, startFunc)
// }
//
// func (k *Kloud) Resize(r *kite.Request) (reqResp interface{}, reqErr error) {
// 	resizeFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
// 		resp, err := p.Resize(m)
// 		if err != nil {
// 			return nil, err
// 		}
//
// 		// some providers might provide empty information, therefore do not
// 		// update anything for them
// 		if resp == nil {
// 			return resp, nil
// 		}
//
// 		err = k.Storage.Update(m.Id, &StorageData{
// 			Type: "resize",
// 			Data: map[string]interface{}{
// 				"ipAddress":    resp.IpAddress,
// 				"domainName":   resp.DomainName,
// 				"instanceId":   resp.InstanceId,
// 				"instanceName": resp.InstanceName,
// 			},
// 		})
//
// 		if err != nil {
// 			k.Log.Error("[%s] updating data after resize method was not possible: %s",
// 				m.Id, err.Error())
// 		}
//
// 		return resp, nil
// 	}
//
// 	return k.coreMethods(r, resizeFunc)
// }
//
// func (k *Kloud) Reinit(r *kite.Request) (resp interface{}, reqErr error) {
// 	reinitFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
// 		resp, err := p.Reinit(m)
// 		if err != nil {
// 			return nil, err
// 		}
//
// 		// some providers might provide empty information, therefore do not
// 		// update anything for them
// 		if resp == nil {
// 			return resp, nil
// 		}
//
// 		// if the username is not explicit changed, assign the original username to it
// 		if resp.Username == "" {
// 			resp.Username = m.Username
// 		}
//
// 		err = k.Storage.Update(m.Id, &StorageData{
// 			Type: "reinit",
// 			Data: map[string]interface{}{
// 				"ipAddress":    resp.IpAddress,
// 				"domainName":   resp.DomainName,
// 				"instanceId":   resp.InstanceId,
// 				"instanceName": resp.InstanceName,
// 				"queryString":  resp.KiteQuery,
// 			},
// 		})
//
// 		return resp, err
// 	}
//
// 	return k.coreMethods(r, reinitFunc)
// }
//
// func (k *Kloud) Stop(r *kite.Request) (resp interface{}, reqErr error) {
// 	stopFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
// 		err := p.Stop(m)
// 		if err != nil {
// 			return nil, err
// 		}
//
// 		err = k.Storage.Update(m.Id, &StorageData{
// 			Type: "stop",
// 			Data: map[string]interface{}{
// 				"ipAddress": "",
// 			},
// 		})
//
// 		return nil, err
// 	}
//
// 	return k.coreMethods(r, stopFunc)
// }
//
// func (k *Kloud) Restart(r *kite.Request) (resp interface{}, reqErr error) {
// 	restartFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
// 		err := p.Restart(m)
// 		return nil, err
// 	}
//
// 	return k.coreMethods(r, restartFunc)
// }
//
// func (k *Kloud) Destroy(r *kite.Request) (resp interface{}, reqErr error) {
// 	destroyFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
// 		err := p.Destroy(m)
// 		if err != nil {
// 			return nil, err
// 		}
//
// 		// purge the data too
// 		err = k.Storage.Delete(m.Id)
// 		return nil, err
// 	}
//
// 	return k.coreMethods(r, destroyFunc)
// }
//
// func (k *Kloud) Info(r *kite.Request) (infoResp interface{}, infoErr error) {
// 	machine, err := k.PrepareMachine(r)
// 	if err != nil {
// 		return nil, err
// 	}
//
// 	defer func() {
// 		if infoErr != nil {
// 			k.Log.Error("[%s] info failed. err: %s", machine.Id, infoErr.Error())
// 		}
// 	}()
//
// 	if machine.State == machinestate.NotInitialized {
// 		return &protocol.InfoArtifact{
// 			State: machinestate.NotInitialized,
// 			Name:  "not-initialized-instance",
// 		}, nil
// 	}
//
// 	provider, ok := k.providers[machine.Provider]
// 	if !ok {
// 		return nil, NewError(ErrProviderAvailable)
// 	}
//
// 	controller, ok := provider.(protocol.Provider)
// 	if !ok {
// 		return nil, NewError(ErrProviderNotImplemented)
// 	}
//
// 	response, err := controller.Info(machine)
// 	if err != nil {
// 		return nil, err
// 	}
//
// 	if response.State == machinestate.Unknown {
// 		response.State = machine.State
// 	}
//
// 	return response, nil
// }

// coreMethods is running and returning the response for the given machineFunc.
// This method is used to avoid duplicate codes in many codes (because we do
// the same steps for each of them).
func (k *Kloud) coreMethods(r *kite.Request, fn machineFunc) (result interface{}, reqErr error) {
	// calls with zero arguments causes args to be nil. Check it that we
	// don't get a beloved panic
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args struct {
		MachineId string
		Provider  string
		Reason    string
	}

	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, NewError(ErrMachineIdMissing)
	}

	// Lock the machine id so no one else can access it. It means this
	// kloud instance is now responsible for this machine id. Its basically
	// a distributed lock. It's unlocked when there is an error or if the
	// method call is finished (unlocking is done inside the responsible
	// method calls).
	if r.Method != "info" {
		if err := k.Locker.Lock(args.MachineId); err != nil {
			return nil, err
		}

		// if something goes wrong after step reset the document which is was
		// set in the by previous step by Locker.Lock(). If there is no error,
		// the lock will be unlocked in the respective method  function.
		defer func() {
			if reqErr != nil {
				// otherwise that means Locker.Lock or something else in
				// ControlFunc failed. Reset the lock again so it can be acquired by
				// others.
				k.Locker.Unlock(args.MachineId)
			}
		}()
	}

	k.Log.Debug("args %+v", args)

	provider, ok := k.providers[args.Provider]
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	p, ok := provider.(Provider)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	machine, err := p.Get(args.MachineId)
	if err != nil {
		return nil, err
	}

	stater, ok := machine.(Stater)
	if !ok {
		return nil, fmt.Errorf("'%s' doesn't support State()", args.Provider)
	}
	state := stater.State()

	ctx := request.NewContext(context.Background(), r)
	if k.ContextCreator != nil {
		ctx = k.ContextCreator(ctx)
	}

	// each method has his own unique eventer
	eventId := r.Method + "-" + args.MachineId
	ev := k.NewEventer(eventId)
	ctx = eventer.NewContext(ctx, ev)

	// get our state pair. A state pair defines the initial and final state of
	// a method.  For example, for "restart" method the initial state is
	// "rebooting" and the final "running.
	s, ok := states[r.Method]
	if !ok {
		return nil, fmt.Errorf("no state pair available for %s", r.Method)
	}

	// check if the argument has any Reason, and add it to the existing reason.
	initialReason := fmt.Sprintf("Machine is '%s' due user command: '%s'.", s.initial, r.Method)
	if args.Reason != "" {
		initialReason += "Custom reason: " + args.Reason
	}

	// now mark that we are starting...
	k.Storage.UpdateState(args.MachineId, initialReason, s.initial)

	// push the first event so it's filled with it, let people know that we're
	// starting.
	ev.Push(&eventer.Event{
		Message: fmt.Sprintf("Starting %s", r.Method),
		Status:  s.initial,
	})

	// Start our core method in a goroutine to not block it for the client
	// side. However we do return an event id which is an unique for tracking
	// the current status of the running method.
	go func() {
		k.idlock.Get(args.MachineId).Lock()
		defer k.idlock.Get(args.MachineId).Unlock()

		k.Log.Info("[%s] ========== %s started (user: %s) ==========",
			args.MachineId, strings.ToUpper(r.Method), r.Username)

		start := time.Now()

		status := s.final
		finishReason := fmt.Sprintf("Machine is '%s' due user command: '%s'", s.final, r.Method)
		msg := fmt.Sprintf("%s is finished successfully.", r.Method)
		eventErr := ""

		err := fn(ctx, machine)
		if err != nil {
			k.Log.Error("[%s] %s failed. State is set back to origin '%s'. err: %s",
				args.MachineId, r.Method, state, err.Error())

			status = state

			msg = ""

			// special case `NetworkOut` error since client relies on this
			// to show a modal
			if strings.Contains(err.Error(), "NetworkOut") {
				msg = err.Error()
			}

			// special case `plan is expired` error since client relies on this
			// to show a modal
			if strings.Contains(strings.ToLower(err.Error()), "plan is expired") {
				msg = err.Error()
			}

			eventErr = fmt.Sprintf("%s failed. Please contact support.", r.Method)
			finishReason = fmt.Sprintf("User command: '%s' failed. Setting back to state: %s",
				r.Method, state)

			k.Log.Info("[%s] ========== %s failed (user: %s) ==========",
				args.MachineId, strings.ToUpper(r.Method), r.Username)
		} else {
			totalDuration := time.Since(start)
			k.Log.Info("[%s] ========== %s finished with success (user: %s, duration: %s) ==========",
				args.MachineId, strings.ToUpper(r.Method), r.Username, totalDuration)
		}

		if args.Reason != "" {
			finishReason += "Custom reason: " + args.Reason
		}

		// update final status in storage
		k.Storage.UpdateState(args.MachineId, finishReason, status)

		// update final status in storage
		ev.Push(&eventer.Event{
			Message:    msg,
			Status:     status,
			Percentage: 100,
			Error:      eventErr,
		})

		// unlock distributed lock
		k.Locker.Unlock(args.MachineId)
	}()

	return ControlResult{
		EventId: eventId,
		State:   s.initial,
	}, nil
}

func (k *Kloud) PrepareMachine(r *kite.Request) (resp *protocol.Machine, reqErr error) {
	// calls with zero arguments causes args to be nil. Check it that we
	// don't get a beloved panic
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args struct {
		MachineId string
	}

	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, NewError(ErrMachineIdMissing)
	}

	// Lock the machine id so no one else can access it. It means this
	// kloud instance is now responsible for this machine id. Its basically
	// a distributed lock. It's unlocked when there is an error or if the
	// method call is finished (unlocking is done inside the responsible
	// method calls).
	if r.Method != "info" {
		if err := k.Locker.Lock(args.MachineId); err != nil {
			return nil, err
		}

		// if something goes wrong after step reset the document which is was
		// set in the by previous step by Locker.Lock(). If there is no error,
		// the lock will be unlocked in the respective method  function.
		defer func() {
			if reqErr != nil {
				// otherwise that means Locker.Lock or something else in
				// ControlFunc failed. Reset the lock again so it can be acquired by
				// others.
				k.Locker.Unlock(args.MachineId)
			}
		}()
	}

	// Get all the data we need.
	machine, err := k.Storage.Get(args.MachineId)
	if err != nil {
		return nil, err
	}

	if machine.Username == "" {
		return nil, NewError(ErrSignUsernameEmpty)
	}

	return machine, nil
}

func (k *Kloud) GetMachine(r *kite.Request) (resp interface{}, reqErr error) {
	// calls with zero arguments causes args to be nil. Check it that we
	// don't get a beloved panic
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args struct {
		MachineId string
		Provider  string
	}

	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, NewError(ErrMachineIdMissing)
	}

	// Lock the machine id so no one else can access it. It means this
	// kloud instance is now responsible for this machine id. Its basically
	// a distributed lock. It's unlocked when there is an error or if the
	// method call is finished (unlocking is done inside the responsible
	// method calls).
	if r.Method != "info" {
		if err := k.Locker.Lock(args.MachineId); err != nil {
			return nil, err
		}

		// if something goes wrong after step reset the document which is was
		// set in the by previous step by Locker.Lock(). If there is no error,
		// the lock will be unlocked in the respective method  function.
		defer func() {
			if reqErr != nil {
				// otherwise that means Locker.Lock or something else in
				// ControlFunc failed. Reset the lock again so it can be acquired by
				// others.
				k.Locker.Unlock(args.MachineId)
			}
		}()
	}

	provider, ok := k.providers[args.Provider]
	if !ok {
		return nil, NewError(ErrProviderAvailable)
	}

	p, ok := provider.(Provider)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	return p.Get(args.MachineId)
}
