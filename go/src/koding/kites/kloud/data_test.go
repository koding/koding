package main

import (
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/kloud/machinestate"
	"time"
)

var (
	DIGITALOCEAN_CLIENT_ID = "2d314ba76e8965c451f62d7e6a4bc56f"
	DIGITALOCEAN_API_KEY   = "4c88127b50c0c731aeb5129bdea06deb"

	RACKSPACE_USERNAME = "kodinginc"
	RACKSPACE_PASSWORD = "frjJapvap3Ox!Uvk"
	RACKSPACE_API_KEY  = "96d6388ccb936f047fd35eb29c36df17"
)

var (
	TestProviderData = map[string]*kloud.MachineData{
		"rackspace_id0": &kloud.MachineData{
			Provider: "rackspace",
			Credential: &kloud.Credential{
				Meta: map[string]interface{}{
					"username": RACKSPACE_USERNAME,
					"apiKey":   RACKSPACE_API_KEY,
				},
			},
			Machine: &kloud.Machine{
				Provider: "rackspace",
				Status: struct {
					State      string    `bson:"state"`
					ModifiedAt time.Time `bson:"modifiedAt"`
				}{
					State:      machinestate.NotInitialized.String(),
					ModifiedAt: time.Now(),
				},
				Meta: map[string]interface{}{
					"type": "rackspace",
				},
			},
		},
		"digitalocean_id0": &kloud.MachineData{
			Provider: "digitalocean",
			Credential: &kloud.Credential{
				Meta: map[string]interface{}{
					"clientId": DIGITALOCEAN_CLIENT_ID,
					"apiKey":   DIGITALOCEAN_API_KEY,
				},
			},
			Machine: &kloud.Machine{
				Provider: "digitalocean",
				Status: struct {
					State      string    `bson:"state"`
					ModifiedAt time.Time `bson:"modifiedAt"`
				}{
					State:      machinestate.NotInitialized.String(),
					ModifiedAt: time.Now(),
				},
				Meta: map[string]interface{}{
					"type":          "digitalocean",
					"clientId":      DIGITALOCEAN_CLIENT_ID,
					"apiKey":        DIGITALOCEAN_API_KEY,
					"image":         "ubuntu-13-10-x64",
					"region":        "sfo1",
					"size":          "512mb",
					"snapshot_name": "koding-{{timestamp}}",
				},
			},
		},
		"digitalocean_id1": &kloud.MachineData{
			Provider: "digitalocean",
			Credential: &kloud.Credential{
				Meta: map[string]interface{}{
					"clientId": DIGITALOCEAN_CLIENT_ID,
					"apiKey":   DIGITALOCEAN_API_KEY,
				},
			},
			Machine: &kloud.Machine{
				Provider: "digitalocean",
				Status: struct {
					State      string    `bson:"state"`
					ModifiedAt time.Time `bson:"modifiedAt"`
				}{
					State:      machinestate.NotInitialized.String(),
					ModifiedAt: time.Now(),
				},
				Meta: map[string]interface{}{
					"type":          "digitalocean",
					"clientId":      DIGITALOCEAN_CLIENT_ID,
					"apiKey":        DIGITALOCEAN_API_KEY,
					"image":         "ubuntu-13-10-x64",
					"region":        "sfo1",
					"size":          "512mb",
					"snapshot_name": "koding-{{timestamp}}",
				},
			},
		},
		"digitalocean_id2": &kloud.MachineData{
			Provider: "digitalocean",
			Credential: &kloud.Credential{
				Meta: map[string]interface{}{
					"clientId": DIGITALOCEAN_CLIENT_ID,
					"apiKey":   DIGITALOCEAN_API_KEY,
				},
			},
			Machine: &kloud.Machine{
				Provider: "digitalocean",
				Status: struct {
					State      string    `bson:"state"`
					ModifiedAt time.Time `bson:"modifiedAt"`
				}{
					State:      machinestate.NotInitialized.String(),
					ModifiedAt: time.Now(),
				},
				Meta: map[string]interface{}{
					"type":          "digitalocean",
					"clientId":      DIGITALOCEAN_CLIENT_ID,
					"apiKey":        DIGITALOCEAN_API_KEY,
					"image":         "ubuntu-13-10-x64",
					"region":        "sfo1",
					"size":          "512mb",
					"snapshot_name": "koding-{{timestamp}}",
				},
			},
		},
		"amazon-instance": nil,
		"googlecompute":   nil,
	}
)
