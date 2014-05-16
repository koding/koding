package main

import (
	"errors"

	"github.com/koding/kite"
)

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
