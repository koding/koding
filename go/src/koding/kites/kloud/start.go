package main

import (
	"errors"

	"github.com/koding/kite"
)

var startArgs struct {
	MachineID string
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

	controller, ok := c.(Controller)
	if !ok {
		return nil, errors.New("provider doesn't satisfy/support this method.")
	}

	controller.Start(args.MachineID)
	return true, nil
}
