package main

import (
	"fmt"
	"log"

	"github.com/mitchellh/packer/packer"
)

type DigitalOcean struct {
	ClientID string
	ApiKey   string
}

func (d *DigitalOcean) Build(path string) error {
	log.Printf("Digitalocean: Reading template: %s", path)
	template, err := packer.ParseTemplateFile(path, nil)
	if err != nil {
		return fmt.Errorf("Failed to parse template: %s", err)
	}

	if len(template.BuildNames()) != 1 {
		return fmt.Errorf("Failed to find build in the template: %v", template.BuildNames())
	}

	buildName := template.BuildNames()[0]
	if buildName != "digitalocean" {
		return fmt.Errorf("Build name is different than 'digitalocean': %v", buildName)
	}

	log.Println("Digitalocean: Creating build interface")
	build, err := template.Build(buildName, nil)
	if err != nil {
		return err
	}

	fmt.Printf("build.Name() %+v\n", build.Name())

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
