package main

import (
	"errors"
	"fmt"
	"log"

	"github.com/mitchellh/packer/builder/digitalocean"
	"github.com/mitchellh/packer/packer"
	"github.com/mitchellh/packer/provisioner/file"
	"github.com/mitchellh/packer/provisioner/shell"
)

type DigitalOcean struct {
	ClientID string
	ApiKey   string
}

func (d *DigitalOcean) Build(path string) error {
	log.Printf("Digitalocean: Reading template: %s", path)

	userVars := map[string]string{
		"klient_deb":     "klient_0.0.1_amd64.deb",
		"klient_keyname": "kite.key",
		"klient_keydir":  "/opt/kite/klient/key",
	}

	template, err := packer.ParseTemplateFile(path, userVars)
	if err != nil {
		return fmt.Errorf("Failed to parse template: %s", err)
	}

	if len(template.Builders) != 1 {
		return fmt.Errorf("Failed to find build in the template: %v", template.BuildNames())
	}

	if _, ok := template.Builders["digitalocean"]; !ok {
		return errors.New("Build 'digitalocean' does not exist")
	}

	components := &packer.ComponentFinder{
		Builder:     builderFunc,
		Provisioner: provisionerFunc,
	}

	build, err := template.Build("digitalocean", components)
	if err != nil {
		return err
	}

	_, err = build.Prepare()
	if err != nil {
		return err
	}

	return nil
}

func builderFunc(name string) (packer.Builder, error) {
	switch name {
	case "digitalocean":
		return &digitalocean.Builder{}, nil
	}

	return nil, errors.New("no suitable build found")
}

func provisionerFunc(name string) (packer.Provisioner, error) {
	switch name {
	case "file":
		return &file.Provisioner{}, nil
	case "shell":
		return &shell.Provisioner{}, nil
	}

	return nil, errors.New("no suitable provisioner found")
}

func (d *DigitalOcean) Provision() error {
	return nil
}

func (d *DigitalOcean) Start() error   { return nil }
func (d *DigitalOcean) Stop() error    { return nil }
func (d *DigitalOcean) Restart() error { return nil }
func (d *DigitalOcean) Destroy() error { return nil }

func deleteLater() {
	// _, err = build.Run()
	// if err != nil {
	// 	return err
	// }

	// log.Println("Digitalocean: Creating build interface")
	// build, err := template.Build(buildName, components)
	// if err != nil {
	// 	return err
	// }

	// for _, b := range template.Builders {
	// 	fmt.Printf("b.Type %+v\n", b.Type)
	// }
	//
	// variables := make(map[string]string)
	// for k, v := range template.Variables {
	// 	fmt.Printf("v %+v\n", v)
	// 	variables[k] = v.Value
	// }
	//
	// if len(template.BuildNames()) != 1 {
	// 	return fmt.Errorf("Failed to find build in the template: %v", template.BuildNames())
	// }
	//
	// buildName := template.BuildNames()[0]
	// if buildName != "digitalocean" {
	// 	return fmt.Errorf("Build name is different than 'digitalocean': %v", buildName)
	// }
	//
	// builder := digitalocean.Builder{}
	//
	// packerConfig := map[string]interface{}{
	// 	packer.BuildNameConfigKey:     b.name,
	// 	packer.BuilderTypeConfigKey:   template.Builders["digitalocan"].Type
	// 	packer.UserVariablesConfigKey: variables,
	// }
	//
	// // Prepare the builder
	// _, err = builder.Prepare(template.Builders["digitalocean"].RawConfig, packerConfig)
	// if err != nil {
	// 	return err
	// }
	//
	// for _, p := range template.Provisioners {
	// 	fmt.Printf("p.Type %+v\n", p.Type)
	//
	// 	switch p.Type {
	// 	case "file":
	// 		f := file.Provisioner{}
	// 		if err := f.Prepare(p.RawConfig); err != nil {
	// 			return err
	// 		}
	// 	case "shell":
	// 		s := shell.Provisioner{}
	// 		if err := s.Prepare(p.RawConfig); err != nil {
	// 			return err
	// 		}
	// 	}
	//
	// }
}
