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
	handler := func(r *kite.Request) (response interface{}, err error) {
		defer func() {
			if err != nil {
				k.Log.Warning("[controller] %s error: %s", r.Method, err.Error())
			}
		}()

		// calls with zero arguments causes args to be nil. Check it that we
		// don't get a beloved panic
		if r.Args == nil {
			return nil, NewError(ErrNoArguments)
		}

		k.Log.Info("[controller] got a request for method: '%s' with args: %v",
			method, string(r.Args.Raw))

		// this locks are important to prevent consecutive calls from the same
		// user
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

		// call no our kite handler with the the controller context
		return control(r, c)
	}

	k.Kite.HandleFunc(method, handler)
}

// controller returns the Controller struct with all necessary entities
// responsible for the given machine Id. It also calls provider.Prepare before
// returning.
func (k *Kloud) controller(r *kite.Request) (contr *Controller, err error) {
	args := &Controller{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, NewError(ErrMachineIdMissing)
	}

	// Geth all the data we need. It also sets the assignee for the given
	// machine id.
	m, err := k.Storage.Get(args.MachineId, &GetOption{
		IncludeMachine:    true,
		IncludeCredential: true,
	})
	if err != nil {
		return nil, err
	}

	// if something goes wrong reset the assigne which was set in previous step
	// by Storage.Get()
	defer func() {
		if err != nil {
			k.Storage.ResetAssignee(args.MachineId)
		}
	}()

	k.Log.Debug("[controller] got machine data with machineID (%s) : %#v",
		args.MachineId, m.Machine)

	// prevent request if the machine is terminated. However we want the user
	// to be able to build again or get information, therefore build and info
	// should be able to continue, however methods like start/stop/etc.. are
	// forbidden.
	if m.Machine.State().In(machinestate.Terminating, machinestate.Terminated) &&
		!methodHas(r.Method, "build", "info") {
		return nil, NewError(ErrMachineTerminating)
	}

	// now get the machine provider interface, it can DO, AWS, GCE, and so on..
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

func (k *Kloud) info(r *kite.Request, c *Controller) (interface{}, error) {
	defer k.Storage.ResetAssignee(c.MachineId)

	if c.CurrenState == machinestate.NotInitialized {
		return nil, NewError(ErrNotInitialized)
	}

	machOptions := &protocol.MachineOptions{
		MachineId:  c.MachineId,
		Username:   r.Username,
		Eventer:    &eventer.Events{}, // add fake eventer to avoid errors on NewClient at provider
		Credential: c.MachineData.Credential.Meta,
		Builder:    c.MachineData.Machine.Meta,
	}

	info, err := c.Provider.Info(machOptions)
	if err != nil {
		return nil, err
	}

	response := &protocol.InfoResponse{
		State: info.State,
		Name:  info.Name,
	}

	if info.State == machinestate.Unknown {
		response.State = c.CurrenState
	}

	k.Storage.UpdateState(c.MachineId, response.State)

	k.Log.Info("[info] returning response %+v", response)
	return response, nil
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

// coreMethods is running and returning the event id for the methods start,
// stop, restart and destroy. This method is used to avoid duplicate codes in
// start, stop, restart and destroy methods (because we do the same steps for
// each of them)
func (k *Kloud) coreMethods(
	r *kite.Request,
	c *Controller,
	fn func(*protocol.MachineOptions) error,
) (result interface{}, err error) {
	// if something goes wrong reset the assigne which was set in in
	// ControlFunc's Storage.Get method
	defer func() {
		if err != nil {
			k.Storage.ResetAssignee(c.MachineId)
		}
	}()

	// all core methods works only for machines that are initialized
	if c.CurrenState == machinestate.NotInitialized {
		return nil, NewError(ErrNotInitialized)
	}

	// get our state pair. A state pair defines the inital state and the final
	// state. For example, for "restart" method the initial state is
	// "rebooting" and the final "running.
	s, ok := states[r.Method]
	if !ok {
		return nil, fmt.Errorf("no state pair available for %s", r.Method)
	}
	k.Storage.UpdateState(c.MachineId, s.initial)
	c.Eventer = k.NewEventer(r.Method + "-" + c.MachineId)

	machOptions := &protocol.MachineOptions{
		MachineId:  c.MachineId,
		Username:   r.Username,
		Eventer:    c.Eventer,
		Credential: c.MachineData.Credential.Meta,
		Builder:    c.MachineData.Machine.Meta,
	}

	// Start our core method in a goroutine to not block it for the client
	// side. However we do return an event id which is an unique for tracking
	// the current status of the running method.
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
