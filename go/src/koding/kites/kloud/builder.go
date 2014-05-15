package main

import (
	"errors"
	"fmt"

	"github.com/koding/kite"
)

var providers = map[string]Builder{
	"digitalocean": &DigitalOcean{},
}

// Builder is used to create and provisiong a single image or machine for a
// given Provider.
type Builder interface {
	Build(...interface{}) error
}

type buildArgs struct {
	Provider string
	Builder  map[string]interface{}
}

func build(r *kite.Request) (interface{}, error) {
	args := &buildArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	fmt.Printf("args %+v\n", args)

	provider, ok := providers[args.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	if err := provider.Build(args.Builder); err != nil {
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
