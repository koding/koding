package main

import (
	"errors"

	"github.com/koding/kite"
)

var providers = map[string]Provider{
	"digitalocean": &DigitalOcean{},
}

// Provider is used to create and provisiong a single image or machine for a
// given Provider.
type Provider interface {
	Build() error
	Provision() error
}

type buildArgs struct {
	Provider string
}

func build(r *kite.Request) (interface{}, error) {
	args := &buildArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	provider, ok := providers[args.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	if err := provider.Build(); err != nil {
		return nil, err
	}

	if err := provider.Provision(); err != nil {
		return nil, err
	}

	return true, nil
}

// Controller manages a machine
type Controller interface {
	Start() error
	Stop() error
	Restart() error
	Destroy() error
}
