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
	MachineId   string
	Provider    protocol.Provider
	MachineData *MachineData
	Eventer     eventer.Eventer
}

type InfoResponse struct {
	State string
	Data  interface{}
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

	if state == machinestate.NotInitialized {
		return nil, ErrNotInitialized
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
		Eventer:     k.NewEventer(r.Method + "-" + args.MachineId),
	}, nil
}

func (k *Kloud) start(r *kite.Request) (interface{}, error) {
	c, err := k.controller(r)
	if err != nil {
		return nil, err
	}

	k.idlock.Get(r.Username).Lock()
	defer k.idlock.Get(r.Username).Unlock()

	k.Storage.UpdateState(c.MachineId, machinestate.Starting)

	machOptions := &protocol.MachineOptions{
		MachineId: c.MachineId,
		Username:  r.Username,
		Eventer:   c.Eventer,
	}

	if err := c.Provider.Start(machOptions); err != nil {
		return nil, err
	}

	k.Storage.UpdateState(c.MachineId, machinestate.Running)
	return true, nil
}

func (k *Kloud) stop(r *kite.Request) (interface{}, error) {
	c, err := k.controller(r)
	if err != nil {
		return nil, err
	}

	k.idlock.Get(r.Username).Lock()
	defer k.idlock.Get(r.Username).Unlock()

	k.Storage.UpdateState(c.MachineId, machinestate.Stopping)

	machOptions := &protocol.MachineOptions{
		MachineId: c.MachineId,
		Username:  r.Username,
		Eventer:   c.Eventer,
	}

	if err := c.Provider.Stop(machOptions); err != nil {
		return nil, err
	}

	k.Storage.UpdateState(c.MachineId, machinestate.Stopped)
	return true, nil
}

func (k *Kloud) destroy(r *kite.Request) (interface{}, error) {
	c, err := k.controller(r)
	if err != nil {
		return nil, err
	}

	k.idlock.Get(r.Username).Lock()
	defer k.idlock.Get(r.Username).Unlock()

	k.Storage.UpdateState(c.MachineId, machinestate.Terminating)

	k.Log.Info("destroying machine %s on %s", c.MachineId, c.Provider.Name())

	machOptions := &protocol.MachineOptions{
		MachineId: c.MachineId,
		Username:  r.Username,
		Eventer:   c.Eventer,
	}

	go func() {
		k.idlock.Get(r.Username).Lock()
		defer k.idlock.Get(r.Username).Unlock()

		status := machinestate.Terminated
		msg := "Termination is finished successfully."

		err := c.Provider.Destroy(machOptions)
		if err != nil {
			k.Log.Error("Termination machine failed: %s. Machine state is marked as Unknown",
				err.Error())

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

func (k *Kloud) restart(r *kite.Request) (interface{}, error) {
	c, err := k.controller(r)
	if err != nil {
		return nil, err
	}

	k.idlock.Get(r.Username).Lock()
	defer k.idlock.Get(r.Username).Unlock()

	k.Storage.UpdateState(c.MachineId, machinestate.Rebooting)

	k.Log.Info("restarting machine %s on %s", c.MachineId, c.Provider.Name())

	machOptions := &protocol.MachineOptions{
		MachineId: c.MachineId,
		Username:  r.Username,
		Eventer:   c.Eventer,
	}

	go func() {
		k.idlock.Get(r.Username).Lock()
		defer k.idlock.Get(r.Username).Unlock()

		status := machinestate.Running

		err := c.Provider.Restart(machOptions)
		if err != nil {
			k.Log.Error("Restarting machine failed: %s. Machine state is marked as Unknown",
				err.Error())

			status = machinestate.Unknown
		}

		k.Storage.UpdateState(c.MachineId, status)
	}()

	return true, nil
}

func (k *Kloud) info(r *kite.Request) (interface{}, error) {
	c, err := k.controller(r)
	if err != nil {
		return nil, err
	}

	k.idlock.Get(r.Username).Lock()
	defer k.idlock.Get(r.Username).Unlock()

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
