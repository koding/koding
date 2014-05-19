package main

import (
	"errors"

	"koding/kites/kloud/digitalocean"

	"github.com/koding/kite"
)

// Builder is used to create and provisiong a single image or machine for a
// given Provider.
type Builder interface {
	// Prepare is responsible of configuring the builder and validating the
	// given configuration prior Build.
	Prepare(...interface{}) error

	// Build is creating a image and a machine.
	Build(...interface{}) (interface{}, error)
}

type buildArgs struct {
	Provider     string
	SnapshotName string
	Credential   map[string]interface{}
	Builder      map[string]interface{}
}

var (
	defaultSnapshotName = "koding-klient-0.0.1"
	providers           = map[string]interface{}{
		"digitalocean": &digitalocean.DigitalOcean{},
	}
)

func build(r *kite.Request) (interface{}, error) {
	args := &buildArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	p, ok := providers[args.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	provider, ok := p.(Builder)
	if !ok {
		return nil, errors.New("provider doesn't satisfy the builder interface.")
	}

	if err := provider.Prepare(args.Credential, args.Builder); err != nil {
		return nil, err
	}

	snapshotName := defaultSnapshotName
	if args.SnapshotName != "" {
		snapshotName = args.SnapshotName
	}

	artifact, err := provider.Build(snapshotName)
	if err != nil {
		return nil, err
	}

	return artifact, nil
}
