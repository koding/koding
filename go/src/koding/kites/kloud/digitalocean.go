package main

import (
	"fmt"
	"koding/kites/kloud/packer"
)

type DigitalOcean struct {
	ClientID string
	ApiKey   string
}

func (d *DigitalOcean) Build(raws ...interface{}) (err error) {
	data, err := templateData(raws)
	if err != nil {
		return err
	}

	provider := &packer.Provider{
		BuildName: "digitalocean",
		Data:      data,
	}
	fmt.Printf("provider %+v\n", provider)

	return nil

	// return provider.Build()
}

func (d *DigitalOcean) Start() error   { return nil }
func (d *DigitalOcean) Stop() error    { return nil }
func (d *DigitalOcean) Restart() error { return nil }
func (d *DigitalOcean) Destroy() error { return nil }
