package main

import (
	"fmt"
	"log"

	"github.com/mitchellh/packer/builder/digitalocean"
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

	fmt.Printf("template %#v\n", template)

	if len(template.BuildNames()) != 1 {
		return fmt.Errorf("Failed to find build in the template: %v", template.BuildNames())
	}

	buildName := template.BuildNames()[0]
	if buildName != "digitalocean" {
		return fmt.Errorf("Build name is different than 'digitalocean': %v", buildName)
	}

	builder := digitalocean.Builder{}
	fmt.Printf("builder %+v\n", builder)

	s, err := builder.Prepare(template.Builders["digitalocean"].RawConfig)
	if err != nil {
		return err
	}

	fmt.Printf("s %+v\n", s)

	// log.Println("Digitalocean: Preparing environment")
	// envConfig := packer.DefaultEnvironmentConfig()
	// env, err := packer.NewEnvironment(envConfig)
	// if err != nil {
	// 	return err
	// }
	//
	// components := &packer.ComponentFinder{
	// 	Builder:       env.Builder,
	// 	Hook:          env.Hook,
	// 	PostProcessor: env.PostProcessor,
	// 	Provisioner:   env.Provisioner,
	// }

	// log.Println("Digitalocean: Creating build interface")
	// build, err := template.Build(buildName, components)
	// if err != nil {
	// 	return err
	// }

	return nil
}

func (d *DigitalOcean) Provision() error {
	return nil
}

func (d *DigitalOcean) Start() error   { return nil }
func (d *DigitalOcean) Stop() error    { return nil }
func (d *DigitalOcean) Restart() error { return nil }
func (d *DigitalOcean) Destroy() error { return nil }
