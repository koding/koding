package main

import (
	"sync"

	"github.com/koding/kloud"
	"github.com/koding/kloud/machinestate"
)

var (
	DIGITALOCEAN_CLIENT_ID = "2d314ba76e8965c451f62d7e6a4bc56f"
	DIGITALOCEAN_API_KEY   = "4c88127b50c0c731aeb5129bdea06deb"

	RACKSPACE_USERNAME = "kodinginc"
	RACKSPACE_PASSWORD = "frjJapvap3Ox!Uvk"
	RACKSPACE_API_KEY  = "96d6388ccb936f047fd35eb29c36df17"
)

var (
	TestData = make(map[string]*kloud.Machine)
	TestMu   sync.Mutex
)

func GetTestData(id string) *kloud.Machine {
	TestMu.Lock()
	defer TestMu.Unlock()
	return TestData[id]
}

func CreateTestData(provider, id string) {
	data := &kloud.Machine{
		Provider:   provider,
		Credential: map[string]interface{}{},
		Data:       map[string]interface{}{},
		State:      machinestate.NotInitialized,
	}

	TestMu.Lock()
	TestData[id] = data
	TestMu.Unlock()
}

var (
	TestProviderData = map[string]*kloud.Machine{
		"koding_id0": &kloud.Machine{
			Provider: "koding",
			Credential: map[string]interface{}{
				"username": RACKSPACE_USERNAME,
				"apiKey":   RACKSPACE_API_KEY,
			},
			Data:  map[string]interface{}{},
			State: machinestate.NotInitialized,
		},
		"koding_id1": &kloud.Machine{
			Provider: "koding",
			Credential: map[string]interface{}{
				"username": RACKSPACE_USERNAME,
				"apiKey":   RACKSPACE_API_KEY,
			},
			Data:  map[string]interface{}{},
			State: machinestate.NotInitialized,
		},
		"koding_id2": &kloud.Machine{
			Provider: "koding",
			Credential: map[string]interface{}{
				"username": RACKSPACE_USERNAME,
				"apiKey":   RACKSPACE_API_KEY,
			},
			Data:  map[string]interface{}{},
			State: machinestate.NotInitialized,
		},
		"digitalocean_id0": &kloud.Machine{
			Provider: "digitalocean",
			Credential: map[string]interface{}{
				"clientId": DIGITALOCEAN_CLIENT_ID,
				"apiKey":   DIGITALOCEAN_API_KEY,
			},
			Data: map[string]interface{}{
				"type":          "digitalocean",
				"clientId":      DIGITALOCEAN_CLIENT_ID,
				"apiKey":        DIGITALOCEAN_API_KEY,
				"image":         "ubuntu-13-10-x64",
				"region":        "sfo1",
				"size":          "512mb",
				"snapshot_name": "koding-{{timestamp}}",
			},
			State: machinestate.NotInitialized,
		},
		"digitalocean_id1": &kloud.Machine{
			Provider: "digitalocean",
			Credential: map[string]interface{}{
				"clientId": DIGITALOCEAN_CLIENT_ID,
				"apiKey":   DIGITALOCEAN_API_KEY,
			},
			Data: map[string]interface{}{
				"type":          "digitalocean",
				"clientId":      DIGITALOCEAN_CLIENT_ID,
				"apiKey":        DIGITALOCEAN_API_KEY,
				"image":         "ubuntu-13-10-x64",
				"region":        "sfo1",
				"size":          "512mb",
				"snapshot_name": "koding-{{timestamp}}",
			},
			State: machinestate.NotInitialized,
		},
		"digitalocean_id2": &kloud.Machine{
			Provider: "digitalocean",
			Credential: map[string]interface{}{
				"clientId": DIGITALOCEAN_CLIENT_ID,
				"apiKey":   DIGITALOCEAN_API_KEY,
			},
			Data: map[string]interface{}{
				"type":          "digitalocean",
				"clientId":      DIGITALOCEAN_CLIENT_ID,
				"apiKey":        DIGITALOCEAN_API_KEY,
				"image":         "ubuntu-13-10-x64",
				"region":        "sfo1",
				"size":          "512mb",
				"snapshot_name": "koding-{{timestamp}}",
			},
			State: machinestate.NotInitialized,
		},
		"amazon-instance": nil,
		"googlecompute":   nil,
	}
)
