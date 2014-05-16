package main

import (
	"errors"
	"fmt"

	"github.com/koding/kite"
)

type startArgs struct {
	Provider   string
	MachineID  interface{}
	Credential map[string]interface{}
}

func start(r *kite.Request) (interface{}, error) {
	args := &startArgs{}
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

	fmt.Printf("args.MachineID %T\n", args.MachineID)

	if err := controller.Start(args.MachineID); err != nil {
		return nil, err
	}

	return true, nil
}
