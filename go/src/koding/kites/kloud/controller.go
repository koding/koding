package main

import (
	"errors"

	"github.com/koding/kite"
)

// Controller manages a machine
type Controller interface {
	// Setup is needed to initialize the Controller. It should be called before
	// calling the other interface methods
	Setup(...interface{}) error

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

type controllerArgs struct {
	Provider   string
	MachineID  interface{}
	Credential map[string]interface{}
}

func start(r *kite.Request) (interface{}, error) {
	args := &controllerArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	p, ok := providers[args.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	controller, ok := p.(Controller)
	if !ok {
		return nil, errors.New("provider doesn't satisfy controller interface.")
	}

	if err := controller.Setup(args.Credential); err != nil {
		return nil, err
	}

	if err := controller.Start(args.MachineID); err != nil {
		return nil, err
	}

	return true, nil
}

func stop(r *kite.Request) (interface{}, error) {
	args := &controllerArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	p, ok := providers[args.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	controller, ok := p.(Controller)
	if !ok {
		return nil, errors.New("provider doesn't satisfy controller interface.")
	}

	if err := controller.Setup(args.Credential); err != nil {
		return nil, err
	}

	if err := controller.Stop(args.MachineID); err != nil {
		return nil, err
	}

	return true, nil
}

func destroy(r *kite.Request) (interface{}, error) {
	args := &controllerArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	p, ok := providers[args.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	controller, ok := p.(Controller)
	if !ok {
		return nil, errors.New("provider doesn't satisfy controller interface.")
	}

	if err := controller.Setup(args.Credential); err != nil {
		return nil, err
	}

	if err := controller.Destroy(args.MachineID); err != nil {
		return nil, err
	}

	return true, nil
}

func restart(r *kite.Request) (interface{}, error) {
	args := &controllerArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	p, ok := providers[args.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	controller, ok := p.(Controller)
	if !ok {
		return nil, errors.New("provider doesn't satisfy controller interface.")
	}

	if err := controller.Setup(args.Credential); err != nil {
		return nil, err
	}

	if err := controller.Restart(args.MachineID); err != nil {
		return nil, err
	}

	return true, nil
}

func info(r *kite.Request) (interface{}, error) {
	args := &controllerArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	p, ok := providers[args.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	controller, ok := p.(Controller)
	if !ok {
		return nil, errors.New("provider doesn't satisfy controller interface.")
	}

	if err := controller.Setup(args.Credential); err != nil {
		return nil, err
	}

	info, err := controller.Info(args.MachineID)
	if err != nil {
		return nil, err
	}

	return info, nil
}
