package kloud

import (
	"errors"
	"fmt"
	"time"

	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"

	"github.com/koding/kite"
	prot "github.com/koding/kite/protocol"
)

type Controller struct {
	// Incoming arguments
	MachineId    string
	ImageName    string
	InstanceName string
	Username     string

	// Populated later
	CurrenState machinestate.State `json:"-"`
	Provider    protocol.Provider  `json:"-"`
	MachineData *MachineData       `json:"-"`
	Eventer     eventer.Eventer    `json:"-"`
}

type InfoResponse struct {
	State string
	Data  interface{}
}

type controlFunc func(*kite.Request, *Controller) (interface{}, error)

func (k *Kloud) ControlFunc(method string, control controlFunc) {
	handler := func(r *kite.Request) (interface{}, error) {
		// this locks are important to prevent consecutive calls from the same user
		k.idlock.Get(r.Username).Lock()
		defer k.idlock.Get(r.Username).Unlock()

		c, err := k.controller(r)
		if err != nil {
			return nil, err
		}

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
		return nil, errors.New("machineId is missing.")
	}

	m, err := k.Storage.Get(args.MachineId, &GetOption{
		IncludeMachine:    true,
		IncludeCredential: true,
	})
	if err != nil {
		return nil, err
	}

	state := machinestate.States[m.Machine.Status.State]
	if state == 0 {
		return nil, fmt.Errorf("state is unknown: %s", m.Machine.Status.State)
	}

	provider, ok := providers[m.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	if err := provider.Prepare(m.Credential.Meta, m.Machine.Meta); err != nil {
		return nil, err
	}

	return &Controller{
		MachineId:   args.MachineId,
		Provider:    provider,
		MachineData: m,
		Username:    r.Username,
		Eventer:     k.NewEventer(r.Method + "-" + args.MachineId),
		CurrenState: state,
	}, nil
}

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

func (k *Kloud) coreMethods(r *kite.Request, c *Controller, fn func(*protocol.MachineOptions) error) (interface{}, error) {
	// all core methods works only for machines that are initialized
	if c.CurrenState == machinestate.NotInitialized {
		return nil, ErrNotInitialized
	}

	// get our state pair
	s, ok := states[r.Method]
	if !ok {
		return nil, fmt.Errorf("no state pair available for %s", r.Method)
	}

	k.Storage.UpdateState(c.MachineId, s.initial)

	machOptions := &protocol.MachineOptions{
		MachineId: c.MachineId,
		Username:  r.Username,
		Eventer:   c.Eventer,
	}

	go func() {
		k.idlock.Get(r.Username).Lock()
		defer k.idlock.Get(r.Username).Unlock()

		status := s.final
		msg := fmt.Sprintf("%s is finished successfully.", r.Method)

		err := fn(machOptions)
		if err != nil {
			k.Log.Error("%s failed: %s. Machine state is Unknown now.", r.Method, err.Error())
			status = machinestate.Unknown
			msg = err.Error()
		}

		k.Storage.UpdateState(c.MachineId, status)
		c.Eventer.Push(&eventer.Event{
			Message:    msg,
			Status:     status,
			Percentage: 100,
		})
	}()

	return true, nil
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
	if c.CurrenState == machinestate.NotInitialized {
		return nil, ErrNotInitialized
	}

	machOptions := &protocol.MachineOptions{
		MachineId: c.MachineId,
		Username:  r.Username,
		Eventer:   c.Eventer,
	}

	info, err := c.Provider.Info(machOptions)
	if err != nil {
		return nil, err
	}

	return &InfoResponse{
		State: c.MachineData.Machine.Status.State,
		Data:  info,
	}, nil
}

func (k *Kloud) remoteKiteAlive(queryString string) error {
	query, err := prot.KiteFromString(queryString)
	if err != nil {
		return err
	}

	kontrolQuery := prot.KontrolQuery{
		Username:    query.Username,
		ID:          query.ID,
		Hostname:    query.Hostname,
		Name:        query.Name,
		Environment: query.Environment,
		Region:      query.Region,
		Version:     query.Version,
	}

	checkKite := func() error {
		fmt.Println("getting kites")
		kites, err := k.Kite.GetKites(kontrolQuery)
		if err != nil {
			return err
		}

		remoteKite := kites[0]

		fmt.Println("dialing kite")
		if err := remoteKite.Dial(); err != nil {
			return err
		}

		fmt.Println("executing kite.ping")
		resp, err := remoteKite.Tell("kite.ping")
		if err != nil {
			return err
		}

		if resp.MustString() == "pong" {
			return nil
		}

		return fmt.Errorf("wrong response %s", resp.MustString())
	}

	tryUntil := time.Now().Add(time.Minute)
	for {
		if err = checkKite(); err == nil {
			return nil
		}

		if time.Now().After(tryUntil) {
			return fmt.Errorf("Timeout while waiting for kite. Reason: %v", err)
		}

		time.Sleep(time.Second * 3)
	}

	return errors.New("couldn't check remote kite")
}
