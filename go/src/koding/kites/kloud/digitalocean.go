package main

import (
	"errors"
	"fmt"
	"koding/kites/kloud/packer"

	"github.com/mitchellh/packer/builder/digitalocean"
)

type DigitalOcean struct {
	Name     string
	Data     []byte
	ClientID string
	ApiKey   string
}

func (d *DigitalOcean) Prepare(raws ...interface{}) (err error) {
	if len(raws) != 2 {
		return errors.New("need at least two arguments")
	}

	creds, ok := raws[0].(map[string]interface{})
	if !ok {
		return fmt.Errorf("malformed credential data %v", raws[0])
	}

	if len(creds) == 0 {
		return errors.New("credential is empty")
	}

	d.ClientID, ok = creds["client_id"].(string)
	if !ok {
		return fmt.Errorf("client_id must be string")
	}

	d.ApiKey, ok = creds["api_key"].(string)
	if !ok {
		return fmt.Errorf("api_key must be string")
	}

	d.Name = "digitalocean"

	d.Data, err = templateData(raws[1])
	if err != nil {
		return err
	}

	return nil
}

func (d *DigitalOcean) Build() (err error) {
	provider := &packer.Provider{
		BuildName: "digitalocean",
		Data:      d.Data,
	}
	fmt.Printf("provider %+v\n", provider)

	client := digitalocean.DigitalOceanClient{}
	do := client.New(d.ClientID, d.ApiKey)
	images, err := do.Images()
	if err != nil {
		return err
	}

	fmt.Printf("images %+v\n", images)
	return nil

	// return provider.Build()
}

func (d *DigitalOcean) Start() error   { return nil }
func (d *DigitalOcean) Stop() error    { return nil }
func (d *DigitalOcean) Restart() error { return nil }
func (d *DigitalOcean) Destroy() error { return nil }
