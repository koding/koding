package kloud

import (
	"fmt"

	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"

	"github.com/koding/kite"
)

type Controller struct {
	// Incoming arguments
	MachineId    string
	ImageName    string
	InstanceName string

	// Populated later
	CurrenState machinestate.State `json:"-"`
	Provider    protocol.Provider  `json:"-"`
	MachineData *MachineData       `json:"-"`
	Eventer     eventer.Eventer    `json:"-"`
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

func (k *Kloud) ControlFunc(method string, control controlFunc) {
	handler := func(r *kite.Request) (interface{}, error) {
		if r.Args == nil {
			return nil, NewError(ErrNoArguments)
		}

		k.Log.Info("[controller] got a request for method: '%s' with args: %v",
			method, string(r.Args.Raw))

		// this locks are important to prevent consecutive calls from the same user
		k.idlock.Get(r.Username).Lock()
		c, err := k.controller(r)
		if err != nil {
			k.idlock.Get(r.Username).Unlock()
			return nil, err
		}
		k.idlock.Get(r.Username).Unlock()

		// now lock for machine-ids
		k.idlock.Get(c.MachineId).Lock()
		defer k.idlock.Get(c.MachineId).Unlock()

		return control(r, c)
	}

	k.Kite.HandleFunc(method, handler)
}

// controller returns the Controller struct with all necessary entities
// responsible for the given machine Id. It also calls provider.Prepare before
// returning.
func (k *Kloud) controller(r *kite.Request) (*Controller, error) {
	args := &Controller{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, NewError(ErrMachineIdMissing)
	}

	m, err := k.Storage.Get(args.MachineId, &GetOption{
		IncludeMachine:    true,
		IncludeCredential: true,
	})
	if err != nil {
		return nil, err
	}

	k.Log.Debug("[controller] got machine data with machineID (%s) : %#v", args.MachineId, m.Machine)

	// prevent request if the machine is terminated. However we want the user
	// to be able to build again
	if (m.Machine.State() == machinestate.Terminating ||
		m.Machine.State() == machinestate.Terminated) &&
		r.Method != "build" {
		return nil, NewError(ErrMachineTerminating)
	}

	provider, err := k.GetProvider(m.Provider)
	if err != nil {
		return nil, err
	}

	return &Controller{
		MachineId:    args.MachineId,
		ImageName:    args.ImageName,
		InstanceName: args.InstanceName,
		Provider:     provider,
		MachineData:  m,
		CurrenState:  m.Machine.State(),
		Eventer:      k.NewEventer(r.Method + "-" + args.MachineId),
	}, nil
}

// coreMethods is running and returning the event id for the methods start,
// stop, restart and destroy. This method is used to avoid duplication in other
// methods.
func (k *Kloud) coreMethods(r *kite.Request, c *Controller, fn func(*protocol.MachineOptions) error) (interface{}, error) {
	// all core methods works only for machines that are initialized
	if c.CurrenState == machinestate.NotInitialized {
		return nil, NewError(ErrNotInitialized)
	}

	// get our state pair
	s, ok := states[r.Method]
	if !ok {
		return nil, fmt.Errorf("no state pair available for %s", r.Method)
	}
	k.Storage.UpdateState(c.MachineId, s.initial)

	machOptions := &protocol.MachineOptions{
		MachineId:  c.MachineId,
		Username:   r.Username,
		Eventer:    c.Eventer,
		Credential: c.MachineData.Credential.Meta,
		Builder:    c.MachineData.Machine.Meta,
	}

	go func() {
		k.idlock.Get(c.MachineId).Lock()
		defer k.idlock.Get(c.MachineId).Unlock()

		status := s.final
		msg := fmt.Sprintf("%s is finished successfully.", r.Method)

		k.Log.Info("[controller]: running method %s with mach options %v", r.Method, machOptions)
		err := fn(machOptions)
		if err != nil {
			k.Log.Error("[controller] %s failed: %s. Machine state is Unknown now.",
				r.Method, err.Error())

			status = s.initial
			msg = err.Error()
		} else {
			k.Log.Info("[%s] is successfull. State is now: %+v", r.Method, status)
		}

		k.Storage.UpdateState(c.MachineId, status)
		k.Storage.ResetAssignee(c.MachineId)
		c.Eventer.Push(&eventer.Event{
			Message:    msg,
			Status:     status,
			Percentage: 100,
		})
	}()

	return ControlResult{
		EventId: c.Eventer.Id(),
		State:   s.initial,
	}, nil
}

func (k *Kloud) start(r *kite.Request, c *Controller) (interface{}, error) {
	fn := func(m *protocol.MachineOptions) error {
		return c.Provider.Start(m)
	}

	return k.coreMethods(r, c, fn)
}

func (k *Kloud) stop(r *kite.Request, c *Controller) (interface{}, error) {
	fn := func(m *protocol.MachineOptions) error {
		return c.Provider.Stop(m)
	}

	return k.coreMethods(r, c, fn)
}

func (k *Kloud) destroy(r *kite.Request, c *Controller) (interface{}, error) {
	fn := func(m *protocol.MachineOptions) error {
		return c.Provider.Destroy(m)
	}

	return k.coreMethods(r, c, fn)
}

func (k *Kloud) restart(r *kite.Request, c *Controller) (interface{}, error) {
	fn := func(m *protocol.MachineOptions) error {
		return c.Provider.Restart(m)
	}

	return k.coreMethods(r, c, fn)
}

func (k *Kloud) info(r *kite.Request, c *Controller) (interface{}, error) {
	defer k.Storage.ResetAssignee(c.MachineId)

	if c.CurrenState == machinestate.NotInitialized {
		return nil, NewError(ErrNotInitialized)
	}

	machOptions := &protocol.MachineOptions{
		MachineId:  c.MachineId,
		Username:   r.Username,
		Eventer:    c.Eventer,
		Credential: c.MachineData.Credential.Meta,
		Builder:    c.MachineData.Machine.Meta,
	}

	info, err := c.Provider.Info(machOptions)
	if err != nil {
		return nil, err
	}

	response := &protocol.InfoResponse{State: info.State}
	if info.State == machinestate.Unknown {
		response.State = c.CurrenState
	}

	k.Storage.UpdateState(c.MachineId, response.State)

	k.Log.Info("[info] returning response %+v", response)
	return response, nil
}
