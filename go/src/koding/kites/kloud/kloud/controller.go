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

type controlFunc func(*protocol.Machine, protocol.Controller) (interface{}, error)

type statePair struct {
	initial machinestate.State
	final   machinestate.State
}

var states = map[string]*statePair{
	"start":   &statePair{initial: machinestate.Starting, final: machinestate.Running},
	"stop":    &statePair{initial: machinestate.Stopping, final: machinestate.Stopped},
	"destroy": &statePair{initial: machinestate.Terminating, final: machinestate.Terminated},
	"restart": &statePair{initial: machinestate.Rebooting, final: machinestate.Running},
	"resize":  &statePair{initial: machinestate.Pending, final: machinestate.Running},
}

func (k *Kloud) Start(r *kite.Request) (resp interface{}, reqErr error) {
	startFunc := func(m *protocol.Machine, c protocol.Controller) (interface{}, error) {
		if m.State.In(machinestate.Starting, machinestate.Running) {
			return nil, NewErrorMessage("Machine is already starting/running.")
		}

		resp, err := c.Start(m)
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
	resizeFunc := func(m *protocol.Machine, c protocol.Controller) (interface{}, error) {
		resp, err := c.Resize(m)
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

func (k *Kloud) Stop(r *kite.Request) (resp interface{}, reqErr error) {
	stopFunc := func(m *protocol.Machine, c protocol.Controller) (interface{}, error) {
		if m.State.In(machinestate.Stopped, machinestate.Stopping) {
			return nil, NewErrorMessage("Machine is already stopping/stopped.")
		}

		err := c.Stop(m)
		return nil, err
	}

	return k.coreMethods(r, stopFunc)
}

func (k *Kloud) Restart(r *kite.Request) (resp interface{}, reqErr error) {
	restartFunc := func(m *protocol.Machine, c protocol.Controller) (interface{}, error) {
		if m.State.In(machinestate.Rebooting) {
			return nil, NewErrorMessage("Machine is already rebooting.")
		}

		err := c.Restart(m)
		return nil, err
	}

	return k.coreMethods(r, restartFunc)
}

func (k *Kloud) Destroy(r *kite.Request) (resp interface{}, reqErr error) {
	destroyFunc := func(m *protocol.Machine, c protocol.Controller) (interface{}, error) {
		err := c.Destroy(m)
		return nil, err
	}

	return k.coreMethods(r, destroyFunc)
}

func (k *Kloud) Info(r *kite.Request) (interface{}, error) {
	machine, err := k.PrepareMachine(r)
	if err != nil {
		return nil, err
	}

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

	controller, ok := provider.(protocol.Controller)
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

	defer func() {
		if reqErr != nil {
			k.Log.Error("[%s] method '%s' failed. err: %s", args.MachineId, r.Method, reqErr.Error())
		}
	}()

	k.Log.Info("[%s] ========== %s called by user: %s ==========",
		args.MachineId, strings.ToUpper(r.Method), r.Username)

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

	k.Log.Debug("[%s] got machine data: %+v", args.MachineId, machine)

	// prevent request if the machine is terminated. However we want the user
	// to be able to build again or get information, therefore build and info
	// should be able to continue, however methods like start/stop/etc.. are
	// forbidden.
	if machine.State.In(machinestate.Terminating, machinestate.Terminated) &&
		!methodHas(r.Method, "build", "info") {
		return nil, NewError(ErrMachineTerminating)
	}

	return machine, nil
}

// coreMethods is running and returning the event id for the methods start,
// stop, restart and destroy. This method is used to avoid duplicate codes in
// start, stop, restart and destroy methods (because we do the same steps for
// each of them).
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

	controller, ok := provider.(protocol.Controller)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	// all core methods works only for machines that are initialized
	if machine.State == machinestate.NotInitialized {
		return nil, NewError(ErrMachineNotInitialized)
	}

	// get our state pair. A state pair defines the initial state and the final
	// state. For example, for "restart" method the initial state is
	// "rebooting" and the final "running.
	s, ok := states[r.Method]
	if !ok {
		return nil, fmt.Errorf("no state pair available for %s", r.Method)
	}

	k.Storage.UpdateState(machine.Id, s.initial)
	machine.Eventer = k.NewEventer(r.Method + "-" + machine.Id)

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
			eventErr = fmt.Sprintf("%s failed. Please contact support.", r.Method)
		} else {
			k.Log.Info("[%s] ========== %s finished (status: %s) ==========",
				machine.Id, strings.ToUpper(r.Method), status)
		}

		// update final status in storage
		k.Storage.UpdateState(machine.Id, status)

		// unlock distributed lock
		k.Locker.Unlock(machine.Id)

		// update final status in storage
		machine.Eventer.Push(&eventer.Event{
			Message:    msg,
			Status:     status,
			Percentage: 100,
			Error:      eventErr,
		})
	}()

	return ControlResult{
		EventId: machine.Eventer.Id(),
		State:   s.initial,
	}, nil
}

// methodHas checks if the method exist for the given methods
func methodHas(method string, methods ...string) bool {
	for _, m := range methods {
		if method == m {
			return true
		}
	}
	return false
}
