package main

import (
	"encoding/json"
	"koding/kites/kloud/packer"
)

type DigitalOcean struct {
	ClientID string
	ApiKey   string
}

func (d *DigitalOcean) Build(raws ...interface{}) (err error) {
	packerTemplate := map[string]interface{}{}
	packerTemplate["builders"] = raws
	packerTemplate["provisioners"] = klientProvisioner

	data, err := json.Marshal(packerTemplate)
	if err != nil {
		return err
	}

	provider := &packer.Provider{Data: data}

	template, err := provider.NewTemplate()
	if err != nil {
		return err
	}

	// for _, t := range template.Builders {
	// 	fmt.Printf("t %+v\n", t)
	// }

	// artifacts, err := provider.Build()
	// if err != nil {
	// 	return err
	// }
	//
	// for _, a := range artifacts {
	// 	fmt.Println(a.Files(), a.BuilderId(), a.Id(), a.String())
	// }

	return nil
}

func (d *DigitalOcean) Start() error   { return nil }
func (d *DigitalOcean) Stop() error    { return nil }
func (d *DigitalOcean) Restart() error { return nil }
func (d *DigitalOcean) Destroy() error { return nil }
