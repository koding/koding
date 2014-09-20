package kloud

import (
	"fmt"
	"strings"

	"github.com/koding/kite"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
)

type Controller struct {
	// Incoming arguments
	MachineId string

	// Populated later
	CurrentState machinestate.State `json:"-"`
	ProviderName string             `json:"-"`
	Provider     interface{}        `json:"-"`
	Machine      *protocol.Machine  `json:"-"`
	Eventer      eventer.Eventer    `json:"-"`
	Username     string
}

type ControlResult struct {
	State   machinestate.State `json:"state"`
	EventId string             `json:"eventId"`
}

type controlFunc func(*kite.Request, *Controller) (interface{}, error)

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

func (k *Kloud) Build(r *kite.Request) (interface{}, error) {
	b := &Build{}
	b.Kloud = k

	return k.ControlFunc(b.prepare).ServeKite(r)
}

func (k *Kloud) Start(r *kite.Request) (interface{}, error) {
	return k.ControlFunc(k.start).ServeKite(r)
}

func (k *Kloud) Stop(r *kite.Request) (interface{}, error) {
	return k.ControlFunc(k.stop).ServeKite(r)
}

func (k *Kloud) Restart(r *kite.Request) (interface{}, error) {
	return k.ControlFunc(k.restart).ServeKite(r)
}

func (k *Kloud) Destroy(r *kite.Request) (interface{}, error) {
	return k.ControlFunc(k.destroy).ServeKite(r)
}

func (k *Kloud) Info(r *kite.Request) (interface{}, error) {
	return k.ControlFunc(k.info).ServeKite(r)
}

func (k *Kloud) Resize(r *kite.Request) (interface{}, error) {
	return k.ControlFunc(k.resize).ServeKite(r)
}

func (k *Kloud) ControlFunc(control controlFunc) kite.Handler {
	return kite.HandlerFunc(func(r *kite.Request) (response interface{}, err error) {
		// calls with zero arguments causes args to be nil. Check it that we
		// don't get a beloved panic
		if r.Args == nil {
			return nil, NewError(ErrNoArguments)
		}

		args := &Controller{}
		if err := r.Args.One().Unmarshal(args); err != nil {
			return nil, err
		}

		defer func() {
			if err != nil {
				k.Log.Error("[%s] method '%s' failed. err: %s", args.MachineId, r.Method, err.Error())
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
		}

		// if something goes wrong after step reset the assignee which is was
		// set in the by previous step by Locker.Lock(). If there is no error,
		// Assignee is going to be reseted in the respective method function.
		defer func() {
			if err != nil && r.Method != "info" {
				// otherwise that means Locker.Lock or something else in
				// ControlFunc failed. Reset the lock again so it can be acquired by
				// others.
				k.Locker.Unlock(args.MachineId)
			}
		}()

		// Get all the data we need.
		machine, err := k.Storage.Get(args.MachineId, r.Username)
		if err != nil {
			return nil, err
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

		// now get the machine provider interface, it can be DO, AWS, GCE, and so on..
		provider, ok := k.providers[machine.Provider]
		if !ok {
			NewError(ErrProviderAvailable)
		}

		// our Controller context
		c := &Controller{
			MachineId:    args.MachineId,
			ProviderName: machine.Provider,
			Provider:     provider,
			Machine:      machine,
			CurrentState: machine.State,
		}

		// now finally call our kite handler with the controller context, run
		// forrest run...!
		return control(r, c)
	})
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

func (k *Kloud) info(r *kite.Request, c *Controller) (resp interface{}, err error) {
	if c.CurrentState == machinestate.NotInitialized {
		return &protocol.InfoArtifact{
			State: machinestate.NotInitialized,
			Name:  "not-initialized-instance",
		}, nil
	}

	machOptions := c.Machine

	// add fake eventer to avoid errors on NewClient at provider, the info method doesn't use it
	machOptions.Eventer = &eventer.Events{}

	controller, ok := c.Provider.(protocol.Controller)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	response, err := controller.Info(machOptions)
	if err != nil {
		return nil, err
	}

	if response.State == machinestate.Unknown {
		response.State = c.CurrentState
	}

	return response, nil
}

func (k *Kloud) resize(r *kite.Request, c *Controller) (interface{}, error) {
	resizer, ok := c.Provider.(protocol.Resizer)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	// unlock once we are finished
	k.Locker.Unlock(c.MachineId)

	c.Machine.Eventer = k.NewEventer(r.Method + "-" + c.MachineId)

	resp, err := resizer.Resize(c.Machine)
	if err != nil {
		return nil, err
	}

	// some providers might provide empty information, therefore do not
	// update anything for them
	if resp == nil {
		return "resized", nil
	}

	err = k.Storage.Update(c.MachineId, &StorageData{
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

	k.Log.Info("[%s] ========== %s finished ==========", c.MachineId, strings.ToUpper(r.Method))
	return "resized", nil
}

func (k *Kloud) start(r *kite.Request, c *Controller) (interface{}, error) {
	if c.CurrentState.In(machinestate.Starting, machinestate.Running) {
		return nil, NewErrorMessage("Machine is already starting/running.")
	}

	fn := func(m *protocol.Machine) error {
		controller, ok := c.Provider.(protocol.Controller)
		if !ok {
			return NewError(ErrProviderNotImplemented)
		}

		resp, err := controller.Start(m)
		if err != nil {
			return err
		}

		// some providers might provide empty information, therefore do not
		// update anything for them
		if resp == nil {
			return nil
		}

		err = k.Storage.Update(c.MachineId, &StorageData{
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
				c.MachineId, err.Error())
		}

		// do not return the error, the machine is already prepared and
		// started, it should be ready
		return nil
	}

	return k.coreMethods(r, c, fn)
}

func (k *Kloud) stop(r *kite.Request, c *Controller) (interface{}, error) {
	if c.CurrentState.In(machinestate.Stopped, machinestate.Stopping) {
		return nil, NewErrorMessage("Machine is already stopping/stopped.")
	}

	fn := func(m *protocol.Machine) error {
		controller, ok := c.Provider.(protocol.Controller)
		if !ok {
			return NewError(ErrProviderNotImplemented)
		}

		return controller.Stop(m)
	}

	return k.coreMethods(r, c, fn)
}

func (k *Kloud) destroy(r *kite.Request, c *Controller) (interface{}, error) {
	fn := func(m *protocol.Machine) error {
		controller, ok := c.Provider.(protocol.Controller)
		if !ok {
			return NewError(ErrProviderNotImplemented)
		}
		return controller.Destroy(m)
	}

	return k.coreMethods(r, c, fn)
}

func (k *Kloud) restart(r *kite.Request, c *Controller) (interface{}, error) {
	if c.CurrentState.In(machinestate.Rebooting) {
		return nil, NewErrorMessage("Machine is already rebooting.")
	}

	fn := func(m *protocol.Machine) error {
		controller, ok := c.Provider.(protocol.Controller)
		if !ok {
			return NewError(ErrProviderNotImplemented)
		}
		return controller.Restart(m)
	}

	return k.coreMethods(r, c, fn)
}

// coreMethods is running and returning the event id for the methods start,
// stop, restart and destroy. This method is used to avoid duplicate codes in
// start, stop, restart and destroy methods (because we do the same steps for
// each of them).
func (k *Kloud) coreMethods(r *kite.Request, c *Controller, fn func(*protocol.Machine) error) (result interface{}, err error) {
	// all core methods works only for machines that are initialized
	if c.CurrentState == machinestate.NotInitialized {
		return nil, NewError(ErrMachineNotInitialized)
	}

	// get our state pair. A state pair defines the initial state and the final
	// state. For example, for "restart" method the initial state is
	// "rebooting" and the final "running.
	s, ok := states[r.Method]
	if !ok {
		return nil, fmt.Errorf("no state pair available for %s", r.Method)
	}
	k.Storage.UpdateState(c.MachineId, s.initial)
	c.Eventer = k.NewEventer(r.Method + "-" + c.MachineId)

	// Start our core method in a goroutine to not block it for the client
	// side. However we do return an event id which is an unique for tracking
	// the current status of the running method.
	go func() {
		k.idlock.Get(c.MachineId).Lock()
		defer k.idlock.Get(c.MachineId).Unlock()

		status := s.final
		msg := fmt.Sprintf("%s is finished successfully.", r.Method)
		eventErr := ""

		machOptions := c.Machine
		machOptions.Eventer = c.Eventer

		k.Log.Debug("[%s] running method %s with mach options %v", c.MachineId, r.Method, machOptions)
		err := fn(machOptions)
		if err != nil {
			k.Log.Error("[%s] %s failed. Machine state did't change and is set back to origin state '%s'. err: %s",
				c.MachineId, r.Method, c.CurrentState, err.Error())

			status = c.CurrentState
			msg = ""
			eventErr = fmt.Sprintf("%s failed. Please contact support.", r.Method)
		} else {
			k.Log.Info("[%s] State is now: %+v", c.MachineId, status)
			k.Log.Info("[%s] ========== %s finished ==========", c.MachineId, strings.ToUpper(r.Method))
		}

		// update final status in storage
		k.Storage.UpdateState(c.MachineId, status)

		// unlock distributed lock
		k.Locker.Unlock(c.MachineId)

		// update final status in storage
		c.Eventer.Push(&eventer.Event{
			Message:    msg,
			Status:     status,
			Percentage: 100,
			Error:      eventErr,
		})
	}()

	return ControlResult{
		EventId: c.Eventer.Id(),
		State:   s.initial,
	}, nil
}
