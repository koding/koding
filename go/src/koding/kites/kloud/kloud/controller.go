package kloud

import (
	"fmt"
	"strings"

	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"

	"github.com/koding/kite"
)

type ControlResult struct {
	State   machinestate.State `json:"state"`
	EventId string             `json:"eventId"`
}

type controlFunc func(*protocol.Machine, protocol.Provider) (interface{}, error)

type statePair struct {
	initial machinestate.State
	final   machinestate.State
}

var states = map[string]*statePair{
	"build":   &statePair{initial: machinestate.Building, final: machinestate.Running},
	"start":   &statePair{initial: machinestate.Starting, final: machinestate.Running},
	"stop":    &statePair{initial: machinestate.Stopping, final: machinestate.Stopped},
	"destroy": &statePair{initial: machinestate.Terminating, final: machinestate.Terminated},
	"restart": &statePair{initial: machinestate.Rebooting, final: machinestate.Running},
	"resize":  &statePair{initial: machinestate.Pending, final: machinestate.Running},
	"reinit":  &statePair{initial: machinestate.Terminating, final: machinestate.Running},
}

func (k *Kloud) Start(r *kite.Request) (resp interface{}, reqErr error) {
	startFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
		resp, err := p.Start(m)
		if err != nil {
			return nil, err
		}

		// some providers might provide empty information, therefore do not
		// update anything for them
		if resp == nil {
			return resp, nil
		}

		err = k.Storage.Update(m.Id, &StorageData{
			Type: "start",
			Data: map[string]interface{}{
				"ipAddress":    resp.IpAddress,
				"domainName":   resp.DomainName,
				"instanceId":   resp.InstanceId,
				"instanceName": resp.InstanceName,
			},
		})

		if err != nil {
			k.Log.Error("[%s] updating data after start method was not possible: %s",
				m.Id, err.Error())
		}

		// do not return the error, the machine is already prepared and
		// started, it should be ready
		return resp, nil
	}

	return k.coreMethods(r, startFunc)
}

func (k *Kloud) Resize(r *kite.Request) (reqResp interface{}, reqErr error) {
	resizeFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
		resp, err := p.Resize(m)
		if err != nil {
			return nil, err
		}

		// some providers might provide empty information, therefore do not
		// update anything for them
		if resp == nil {
			return resp, nil
		}

		err = k.Storage.Update(m.Id, &StorageData{
			Type: "resize",
			Data: map[string]interface{}{
				"ipAddress":    resp.IpAddress,
				"domainName":   resp.DomainName,
				"instanceId":   resp.InstanceId,
				"instanceName": resp.InstanceName,
			},
		})

		if err != nil {
			k.Log.Error("[%s] updating data after resize method was not possible: %s",
				m.Id, err.Error())
		}

		return resp, nil
	}

	return k.coreMethods(r, resizeFunc)
}

func (k *Kloud) Reinit(r *kite.Request) (resp interface{}, reqErr error) {
	reinitFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
		resp, err := p.Reinit(m)
		if err != nil {
			return nil, err
		}

		// some providers might provide empty information, therefore do not
		// update anything for them
		if resp == nil {
			return resp, nil
		}

		// if the username is not explicit changed, assign the original username to it
		if resp.Username == "" {
			resp.Username = m.Username
		}

		err = k.Storage.Update(m.Id, &StorageData{
			Type: "reinit",
			Data: map[string]interface{}{
				"ipAddress":    resp.IpAddress,
				"domainName":   resp.DomainName,
				"instanceId":   resp.InstanceId,
				"instanceName": resp.InstanceName,
				"queryString":  resp.KiteQuery,
			},
		})

		return resp, err
	}

	return k.coreMethods(r, reinitFunc)
}

func (k *Kloud) Stop(r *kite.Request) (resp interface{}, reqErr error) {
	stopFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
		err := p.Stop(m)
		if err != nil {
			return nil, err
		}

		err = k.Storage.Update(m.Id, &StorageData{
			Type: "stop",
			Data: map[string]interface{}{
				"ipAddress": "",
			},
		})

		return nil, err
	}

	return k.coreMethods(r, stopFunc)
}

func (k *Kloud) Restart(r *kite.Request) (resp interface{}, reqErr error) {
	restartFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
		err := p.Restart(m)
		return nil, err
	}

	return k.coreMethods(r, restartFunc)
}

func (k *Kloud) Destroy(r *kite.Request) (resp interface{}, reqErr error) {
	destroyFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
		err := p.Destroy(m)
		if err != nil {
			return nil, err
		}

		// purge the data too
		err = k.Storage.Delete(m.Id)
		return nil, err
	}

	return k.coreMethods(r, destroyFunc)
}

func (k *Kloud) Info(r *kite.Request) (infoResp interface{}, infoErr error) {
	machine, err := k.PrepareMachine(r)
	if err != nil {
		return nil, err
	}

	defer func() {
		if infoErr != nil {
			k.Log.Error("[%s] info failed. err: %s", machine.Id, infoErr.Error())
		}
	}()

	if machine.State == machinestate.NotInitialized {
		return &protocol.InfoArtifact{
			State: machinestate.NotInitialized,
			Name:  "not-initialized-instance",
		}, nil
	}

	// add fake eventer to avoid errors on NewClient at provider, the info method doesn't use it
	machine.Eventer = &eventer.Events{}

	provider, ok := k.providers[machine.Provider]
	if !ok {
		return nil, NewError(ErrProviderAvailable)
	}

	controller, ok := provider.(protocol.Provider)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	response, err := controller.Info(machine)
	if err != nil {
		return nil, err
	}

	if response.State == machinestate.Unknown {
		response.State = machine.State
	}

	return response, nil
}

// coreMethods is running and returning the response for the given controlFunc.
// This method is used to avoid duplicate codes in many codes (because we do
// the same steps for each of them).
func (k *Kloud) coreMethods(r *kite.Request, fn controlFunc) (result interface{}, reqErr error) {
	machine, err := k.PrepareMachine(r)
	if err != nil {
		return nil, err
	}

	defer func() {
		if reqErr != nil {
			k.Locker.Unlock(machine.Id)
		}
	}()

	provider, ok := k.providers[machine.Provider]
	if !ok {
		return nil, NewError(ErrProviderAvailable)
	}

	controller, ok := provider.(protocol.Provider)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	// Check if the given method is in valid methods of that current state. For
	// example if the method is "build", and the state is "stopped" than this
	// will return an error.
	if !methodIn(r.Method, machine.State.ValidMethods()...) {
		return nil, fmt.Errorf("method '%s' not allowed for current state '%s'. Allowed methods are: %v",
			r.Method, strings.ToLower(machine.State.String()), machine.State.ValidMethods())
	}

	// get our state pair. A state pair defines the initial and final state of
	// a method.  For example, for "restart" method the initial state is
	// "rebooting" and the final "running.
	s, ok := states[r.Method]
	if !ok {
		return nil, fmt.Errorf("no state pair available for %s", r.Method)
	}

	// now mark that we are starting...
	k.Storage.UpdateState(machine.Id, s.initial)

	// each method has his own unique eventer
	machine.Eventer = k.NewEventer(r.Method + "-" + machine.Id)

	// push the first event so it's filled with it, let people know that we're
	// starting.
	machine.Eventer.Push(&eventer.Event{Message: fmt.Sprintf("Starting %s", r.Method), Status: s.initial})

	// Start our core method in a goroutine to not block it for the client
	// side. However we do return an event id which is an unique for tracking
	// the current status of the running method.
	go func() {
		k.idlock.Get(machine.Id).Lock()
		defer k.idlock.Get(machine.Id).Unlock()

		status := s.final
		msg := fmt.Sprintf("%s is finished successfully.", r.Method)
		eventErr := ""

		_, err := fn(machine, controller)
		if err != nil {
			k.Log.Error("[%s] %s failed. State is set back to origin '%s'. err: %s",
				machine.Id, r.Method, machine.State, err.Error())

			status = machine.State
			msg = ""
			eventErr = err.Error()
		} else {
			k.Log.Info("[%s] ========== %s finished (status: %s) ==========",
				machine.Id, strings.ToUpper(r.Method), status)
		}

		// update final status in storage
		k.Storage.UpdateState(machine.Id, status)

		// update final status in storage
		machine.Eventer.Push(&eventer.Event{
			Message:    msg,
			Status:     status,
			Percentage: 100,
			Error:      eventErr,
		})

		// unlock distributed lock
		k.Locker.Unlock(machine.Id)
	}()

	return ControlResult{
		EventId: machine.Eventer.Id(),
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
		k.Log.Info("[%s] ========== %s called by user: %s ==========",
			args.MachineId, strings.ToUpper(r.Method), r.Username)

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

// methodIn checks if the method exist in the given methods
func methodIn(method string, methods ...string) bool {
	for _, m := range methods {
		if method == m {
			return true
		}
	}
	return false
}
