package main

import (
	"errors"
	"fmt"
	"log"
	"os"

	"github.com/mitchellh/packer/builder/digitalocean"
	"github.com/mitchellh/packer/packer"
	"github.com/mitchellh/packer/provisioner/file"
	"github.com/mitchellh/packer/provisioner/shell"
)

type DigitalOcean struct {
	ClientID string
	ApiKey   string
}

func (d *DigitalOcean) Build(path string) (err error) {
	log.Printf("Digitalocean: Reading template: %s", path)

	userVars := map[string]string{
		"do_api_key":     os.Getenv("DIGITALOCEAN_API_KEY"),
		"do_client_id":   os.Getenv("DIGITALOCEAN_CLIENT_ID"),
		"klient_deb":     "klient_0.0.1_amd64.deb",
		"klient_keyname": "kite.key",
		"klient_keydir":  "/opt/kite/klient/key",
	}

	template, err := packer.ParseTemplateFile(path, userVars)
	if err != nil {
		return fmt.Errorf("Failed to parse template: %s", err)
	}

	if len(template.Builders) == 0 {
		return errors.New("No builder is available")
	}

	if len(template.Builders) != 1 {
		return errors.New("Only on builder is supported currently")
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

	defer func() {
		if err != nil {
			build.Cancel()
		}
	}()

	_, err = build.Prepare()
	if err != nil {
		return err
	}

	var artifacts []packer.Artifact
	artifacts, err = build.Run(
		&packer.BasicUi{
			Reader:      os.Stdin,
			Writer:      os.Stdout,
			ErrorWriter: os.Stderr,
		},
		&packer.FileCache{
			CacheDir: os.TempDir(),
		})
	if err != nil {
		return err
	}

	for _, a := range artifacts {
		fmt.Println(a.Files(), a.BuilderId(), a.Id(), a.String())

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
