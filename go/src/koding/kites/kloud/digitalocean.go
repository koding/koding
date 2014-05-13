package main

import (
	"fmt"

	"github.com/mitchellh/packer/packer"
)

type DigitalOcean struct {
	ClientID string
	ApiKey   string
}

func (d *DigitalOcean) Build(path string) error {
	fmt.Println("Building DigitalOcean", path)

	tpl, err := packer.ParseTemplateFile(path, nil)
	if err != nil {
		return fmt.Errorf("Failed to parse template: %s", err)
	}

	fmt.Printf("tpl %+v\n", tpl)

	return nil
}

func (d *DigitalOcean) Provision() error {
	fmt.Println("Provisioning DigitalOcean")

	return nil
}

func (d *DigitalOcean) Start() error   { return nil }
func (d *DigitalOcean) Stop() error    { return nil }
func (d *DigitalOcean) Restart() error { return nil }
func (d *DigitalOcean) Destroy() error { return nil }
