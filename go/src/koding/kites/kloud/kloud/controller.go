package kloud

import (
	"errors"
	"fmt"
	"time"

	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"

	"github.com/koding/kite"
	prot "github.com/koding/kite/protocol"
)

type ControllerArgs struct {
	MachineId string
}

type InfoResponse struct {
	State machinestate.State
	Data  interface{}
}

// provider returns the Provider responsible for the given machine Id. It also
// calls provider.Prepare before returning.
func (k *Kloud) provider(machineId string) (protocol.Provider, error) {
	m, err := k.Storage.Get(machineId, &GetOption{
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

	return provider, nil
}

func (k *Kloud) start(r *kite.Request) (interface{}, error) {
	args := &ControllerArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, errors.New("machineId is missing.")
	}

	k.idlock.Get(r.Username).Lock()
	defer k.idlock.Get(r.Username).Unlock()

	k.Storage.UpdateState(args.MachineId, machinestate.Starting)

	provider, err := k.provider(args.MachineId)
	if err != nil {
		return nil, err
	}

	if err := provider.Start(); err != nil {
		return nil, err
	}

	k.Storage.UpdateState(args.MachineId, machinestate.Running)
	return true, nil
}

func (k *Kloud) stop(r *kite.Request) (interface{}, error) {
	args := &ControllerArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, errors.New("machineId is missing.")
	}

	k.idlock.Get(r.Username).Lock()
	defer k.idlock.Get(r.Username).Unlock()

	k.Storage.UpdateState(args.MachineId, machinestate.Stopping)

	provider, err := k.provider(args.MachineId)
	if err != nil {
		return nil, err
	}

	if err := provider.Stop(); err != nil {
		return nil, err
	}

	k.Storage.UpdateState(args.MachineId, machinestate.Stopped)
	return true, nil
}

func (k *Kloud) destroy(r *kite.Request) (interface{}, error) {
	args := &ControllerArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, errors.New("machineId is missing.")
	}

	k.idlock.Get(r.Username).Lock()
	defer k.idlock.Get(r.Username).Unlock()

	k.Storage.UpdateState(args.MachineId, machinestate.Terminating)

	provider, err := k.provider(args.MachineId)
	if err != nil {
		return nil, err
	}

	if err := provider.Destroy(); err != nil {
		return nil, err
	}
	k.Storage.UpdateState(args.MachineId, machinestate.Terminated)

	return true, nil
}

func (k *Kloud) restart(r *kite.Request) (interface{}, error) {
	args := &ControllerArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, errors.New("machineId is missing.")
	}

	k.idlock.Get(r.Username).Lock()
	defer k.idlock.Get(r.Username).Unlock()

	k.Storage.UpdateState(args.MachineId, machinestate.Rebooting)

	provider, err := k.provider(args.MachineId)
	if err != nil {
		return nil, err
	}

	k.Log.Info("restarting machine %s on %s", args.MachineId, provider.Name())
	if err := provider.Restart(); err != nil {
		return nil, err
	}

	m, err := k.Storage.Get(args.MachineId, &GetOption{
		IncludeMachine:    true,
		IncludeCredential: true,
	})
	if err != nil {
		k.Log.Error(err.Error())
	}

	query, err := prot.KiteFromString(m.Machine.QueryString)
	if err != nil {
		return nil, err
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
			break
		}

		if time.Now().After(tryUntil) {
			return nil, fmt.Errorf("Timeout while waiting for kite. Reason: %v", err)
		}

		time.Sleep(time.Second * 3)
	}

	return true, nil
}

func (k *Kloud) info(r *kite.Request) (interface{}, error) {
	args := &ControllerArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, errors.New("machineId is missing.")
	}

	k.idlock.Get(r.Username).Lock()
	defer k.idlock.Get(r.Username).Unlock()

	provider, err := k.provider(args.MachineId)
	if err != nil {
		return nil, err
	}

	info, err := provider.Info()
	if err != nil {
		return nil, err
	}

	state, err := k.Storage.GetState(args.MachineId)
	if err != nil {
		return nil, err
	}

	return &InfoResponse{
		State: state,
		Data:  info,
	}, nil
}
