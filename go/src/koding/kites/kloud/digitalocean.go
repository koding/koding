package main

import (
	"encoding/json"
	"fmt"
	"koding/kites/kloud/packer"
)

type DigitalOcean struct {
	ClientID string
	ApiKey   string
}

func (d *DigitalOcean) Build(raws ...interface{}) (err error) {
	fakeTemplate := map[string]interface{}{}
	fakeTemplate["builders"] = raws
	fakeTemplate["provisioners"] = klientProvisioner

	data, err := json.Marshal(fakeTemplate)
	if err != nil {
		return err
	}

	provider := &packer.Provider{
		BuildName:    "digitalocean",
		TemplatePath: "testdata/digitalocean_packer.json",
		Data:         data,
	}

	fmt.Printf("string(data) %+v\n", string(data))

	template, err := provider.NewTemplate()
	if err != nil {
		return err
	}

	fmt.Printf("template %+v\n", template)

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
