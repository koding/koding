package main

import (
	"fmt"
	"koding/kites/kloud/packer"
	"log"
	"os"
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

	artifacts, err := packer.NewBuild(path, "digitalocean", vars)
	if err != nil {
		return err
	}

	for _, a := range artifacts {
		fmt.Println(a.Files(), a.BuilderId(), a.Id(), a.String())
	}

	return nil
}

func (d *DigitalOcean) Start() error   { return nil }
func (d *DigitalOcean) Stop() error    { return nil }
func (d *DigitalOcean) Restart() error { return nil }
func (d *DigitalOcean) Destroy() error { return nil }
