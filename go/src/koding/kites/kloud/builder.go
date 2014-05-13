package main

import (
	"errors"

	"github.com/koding/kite"
)

var providers = map[string]Builder{
	"digitalocean": &DigitalOcean{},
}

// Builder is used to create a single image or machine.
type Builder interface {
	Build() error
}

type buildArgs struct {
	Provider string
}

func build(r *kite.Request) (interface{}, error) {
	args := &buildArgs{}
	if err := r.Args.Unmarshal(args); err != nil {
		return nil, err
	}

	builder, ok := providers[args.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	if err := builder.Build(); err != nil {
		return nil, err
	}

	return nil, nil
}

// Provisioner is used to provision a given image
type Provisioner interface {
	Provision() error
}

// Controller manages a machine
type Controller interface {
	Start() error
	Stop() error
	Restart() error
	Destroy() error
}
