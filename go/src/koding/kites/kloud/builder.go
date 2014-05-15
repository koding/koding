package main

import (
	"encoding/json"
	"errors"
	"fmt"

	"github.com/koding/kite"
)

// Builder is used to create and provisiong a single image or machine for a
// given Provider.
type Builder interface {
	Build(...interface{}) error
}

// Controller manages a machine
type Controller interface {
	Start() error
	Stop() error
	Restart() error
	Destroy() error
}

type buildArgs struct {
	Provider string
	Builder  map[string]interface{}
}

var providers = map[string]Builder{
	"digitalocean": &DigitalOcean{},
}

func build(r *kite.Request) (interface{}, error) {
	args := &buildArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	fmt.Printf("args %#v\n", args)

	provider, ok := providers[args.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	if err := provider.Build(args.Builder); err != nil {
		return nil, err
	}

	return true, nil
}

// templateData converts the given raws interface to a []byte data that can
// used to pass into packer.Template()
func templateData(raw interface{}) ([]byte, error) {
	packerTemplate := map[string]interface{}{}
	packerTemplate["builders"] = raw
	packerTemplate["provisioners"] = klientProvisioner

	return json.Marshal(packerTemplate)
}
