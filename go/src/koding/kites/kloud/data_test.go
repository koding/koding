package main

import (
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/kloud/machinestate"
	"time"
)

var (
	TestProviderData = map[string]*kloud.MachineData{
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
