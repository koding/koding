package kloud

import (
	"errors"

	"github.com/koding/kite"
)

// Provider manages a machine. It is used to create and provision a single
// image or machine for a given Provider, to start/stop/destroy/restart a
// machine.
type Provider interface {
	// Prepare is responsible of configuring and initializing the builder and
	// validating the given configuration prior Build.
	Prepare(...interface{}) error

	// Build is creating a image and a machine.
	Build(...interface{}) (map[string]interface{}, error)

	// Start starts the machine
	Start(...interface{}) error

	// Stop stops the machine
	Stop(...interface{}) error

	// Restart restarts the machine
	Restart(...interface{}) error

	// Destroy destroys the machine
	Destroy(...interface{}) error

	// Info returns full information about a single machine
	Info(...interface{}) (interface{}, error)
}

type ControllerArgs struct {
	MachineId string
}

// provider returns the Provider responsible for the given machine Id. It also
// calls provider.Prepare before returning.
func (k *Kloud) provider(machineId string) (Provider, error) {
	m, err := k.Storage.Get(machineId)
	if err != nil {
		return nil, err
	}

	provider, ok := providers[m.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	if err := provider.Prepare(m.Credential, m.Builders); err != nil {
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

	provider, err := k.provider(args.MachineId)
	if err != nil {
		return nil, err
	}

	if err := provider.Start(); err != nil {
		return nil, err
	}

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

	provider, err := k.provider(args.MachineId)
	if err != nil {
		return nil, err
	}

	if err := provider.Stop(); err != nil {
		return nil, err
	}

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

	provider, err := k.provider(args.MachineId)
	if err != nil {
		return nil, err
	}

	if err := provider.Destroy(); err != nil {
		return nil, err
	}

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

	provider, err := k.provider(args.MachineId)
	if err != nil {
		return nil, err
	}

	if err := provider.Restart(); err != nil {
		return nil, err
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

	return info, nil
}
