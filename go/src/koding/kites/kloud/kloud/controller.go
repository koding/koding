package kloud

import (
	"fmt"
	"strings"

	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"

	"github.com/koding/kite"
)

type MachineArgs struct {
	MachineId string
}

type ControlResult struct {
	State   machinestate.State `json:"state"`
	EventId string             `json:"eventId"`
}

type machineFunc func(*protocol.Machine) (interface{}, error)

type statePair struct {
	initial machinestate.State
	final   machinestate.State
}

var states = map[string]*statePair{
	"start":   &statePair{initial: machinestate.Starting, final: machinestate.Running},
	"stop":    &statePair{initial: machinestate.Stopping, final: machinestate.Stopped},
	"destroy": &statePair{initial: machinestate.Terminating, final: machinestate.Terminated},
	"restart": &statePair{initial: machinestate.Rebooting, final: machinestate.Running},
}

func (k *Kloud) Start(r *kite.Request) (resp interface{}, reqErr error) {
	machine, err := k.PrepareMachine(r)
	if err != nil {
		return nil, err
	}

	defer func() {
		if reqErr != nil {
			k.Locker.Unlock(machine.Id)
		}
	}()

	if machine.State.In(machinestate.Starting, machinestate.Running) {
		return nil, NewErrorMessage("Machine is already starting/running.")
	}

	provider, ok := k.providers[machine.Provider]
	if !ok {
		return nil, NewError(ErrProviderAvailable)
	}

	controller, ok := provider.(protocol.Controller)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	startFunc := func(m *protocol.Machine) (interface{}, error) {
		resp, err := controller.Start(m)
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

	return k.coreMethods(r, machine, startFunc)
}

func (k *Kloud) Stop(r *kite.Request) (resp interface{}, reqErr error) {
	machine, err := k.PrepareMachine(r)
	if err != nil {
		return nil, err
	}

	defer func() {
		if reqErr != nil {
			k.Locker.Unlock(machine.Id)
		}
	}()

	if machine.State.In(machinestate.Stopped, machinestate.Stopping) {
		return nil, NewErrorMessage("Machine is already stopping/stopped.")
	}

	provider, ok := k.providers[machine.Provider]
	if !ok {
		return nil, NewError(ErrProviderAvailable)
	}

	controller, ok := provider.(protocol.Controller)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	stopFunc := func(m *protocol.Machine) (interface{}, error) {
		err := controller.Stop(m)
		return nil, err
	}

	return k.coreMethods(r, machine, stopFunc)
}

func (k *Kloud) Restart(r *kite.Request) (resp interface{}, reqErr error) {
	machine, err := k.PrepareMachine(r)
	if err != nil {
		return nil, err
	}

	defer func() {
		if reqErr != nil {
			k.Locker.Unlock(machine.Id)
		}
	}()

	if machine.State.In(machinestate.Rebooting) {
		return nil, NewErrorMessage("Machine is already rebooting.")
	}

	provider, ok := k.providers[machine.Provider]
	if !ok {
		return nil, NewError(ErrProviderAvailable)
	}

	controller, ok := provider.(protocol.Controller)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	restartFunc := func(m *protocol.Machine) (interface{}, error) {
		err := controller.Restart(m)
		return nil, err
	}

	return k.coreMethods(r, machine, restartFunc)
}

func (k *Kloud) Destroy(r *kite.Request) (resp interface{}, reqErr error) {
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

	destroyFunc := func(m *protocol.Machine) (interface{}, error) {
		err := controller.Destroy(m)
		return nil, err
	}

	return k.coreMethods(r, machine, destroyFunc)
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

func (k *Kloud) Resize(r *kite.Request) (interface{}, error) {
	machine, err := k.PrepareMachine(r)
	if err != nil {
		return nil, err
	}

	// unlock once we are finished
	defer k.Locker.Unlock(machine.Id)

	provider, ok := k.providers[machine.Provider]
	if !ok {
		return nil, NewError(ErrProviderAvailable)
	}

	resizer, ok := provider.(protocol.Resizer)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	// TODO: move to PrepareMachine method
	machine.Eventer = k.NewEventer(r.Method + "-" + machine.Id)

	resp, err := resizer.Resize(machine)
	if err != nil {
		return nil, err
	}

	// some providers might provide empty information, therefore do not
	// update anything for them
	if resp == nil {
		return "resized", nil
	}

	err = k.Storage.Update(machine.Id, &StorageData{
		Type: "resize",
		Data: map[string]interface{}{
			"ipAddress":    resp.IpAddress,
			"domainName":   resp.DomainName,
			"instanceId":   resp.InstanceId,
			"instanceName": resp.InstanceName,
		},
	})
	if err != nil {
		return nil, err
	}

	k.Log.Info("[%s] ========== %s finished ==========", machine.Id, strings.ToUpper(r.Method))
	return "resized", nil
}

func (k *Kloud) PrepareMachine(r *kite.Request) (resp *protocol.Machine, reqErr error) {
	// calls with zero arguments causes args to be nil. Check it that we
	// don't get a beloved panic
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	args := MachineArgs{}
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

	k.Log.Debug("[%s] got machine data: %+v", args.MachineId, machine)

	// TODO: Check permission of the user!

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

// methodHas checks if the method exist for the given methods
func methodHas(method string, methods ...string) bool {
	for _, m := range methods {
		if method == m {
			return true
		}
	}
	return false
}

// coreMethods is running and returning the event id for the methods start,
// stop, restart and destroy. This method is used to avoid duplicate codes in
// start, stop, restart and destroy methods (because we do the same steps for
// each of them).
func (k *Kloud) coreMethods(r *kite.Request, m *protocol.Machine, fn machineFunc) (result interface{}, err error) {
	// all core methods works only for machines that are initialized
	if m.State == machinestate.NotInitialized {
		return nil, NewError(ErrMachineNotInitialized)
	}

	// get our state pair. A state pair defines the initial state and the final
	// state. For example, for "restart" method the initial state is
	// "rebooting" and the final "running.
	s, ok := states[r.Method]
	if !ok {
		return nil, fmt.Errorf("no state pair available for %s", r.Method)
	}

	k.Storage.UpdateState(m.Id, s.initial)
	m.Eventer = k.NewEventer(r.Method + "-" + m.Id)

	// Start our core method in a goroutine to not block it for the client
	// side. However we do return an event id which is an unique for tracking
	// the current status of the running method.
	go func() {
		k.idlock.Get(m.Id).Lock()
		defer k.idlock.Get(m.Id).Unlock()

		status := s.final
		msg := fmt.Sprintf("%s is finished successfully.", r.Method)
		eventErr := ""

		k.Log.Debug("[%s] running method %s with mach options %v", m.Id, r.Method, m)
		_, err := fn(m)
		if err != nil {
			k.Log.Error("[%s] %s failed. Machine state did't change and is set back to origin state '%s'. err: %s",
				m.Id, r.Method, m.State, err.Error())

			status = m.State
			msg = ""
			eventErr = fmt.Sprintf("%s failed. Please contact support.", r.Method)
		} else {
			k.Log.Info("[%s] State is now: %+v", m.Id, status)
			k.Log.Info("[%s] ========== %s finished ==========", m.Id, strings.ToUpper(r.Method))
		}

		// update final status in storage
		k.Storage.UpdateState(m.Id, status)

		// unlock distributed lock
		k.Locker.Unlock(m.Id)

		// update final status in storage
		m.Eventer.Push(&eventer.Event{
			Message:    msg,
			Status:     status,
			Percentage: 100,
			Error:      eventErr,
		})
	}()

	return ControlResult{
		EventId: m.Eventer.Id(),
		State:   s.initial,
	}, nil
}
