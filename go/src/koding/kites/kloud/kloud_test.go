package main

import (
	"flag"
	"koding/kites/kloud/digitalocean"
	"log"
	"testing"

	"github.com/fatih/color"
	"github.com/koding/kite"
)

const ()

var (
	kloud        *kite.Kite
	remote       *kite.Client
	flagTestData = flag.String("testdata", "", "Inject test data to build method.")

	DIGITALOCEAN_CLIENT_ID       = "2d314ba76e8965c451f62d7e6a4bc56f"
	DIGITALOCEAN_API_KEY         = "4c88127b50c0c731aeb5129bdea06deb"
	DIGITALOCEAN_TEST_DROPLET_ID = 1657055
)

var TestProviderData = map[string]map[string]interface{}{
	"digitalocean": map[string]interface{}{
		"provider": "digitalocean",
		"credential": map[string]interface{}{
			"client_id": DIGITALOCEAN_CLIENT_ID,
			"api_key":   DIGITALOCEAN_API_KEY,
		},
		"machineId": DIGITALOCEAN_TEST_DROPLET_ID,
		"builder": map[string]interface{}{
			"type":          "digitalocean",
			"client_id":     DIGITALOCEAN_CLIENT_ID,
			"api_key":       DIGITALOCEAN_API_KEY,
			"image":         "ubuntu-13-10-x64",
			"region":        "ams2",
			"size":          "512mb",
			"snapshot_name": "koding-{{timestamp}}",
		},
	},
	"amazon-instance": nil,
	"googlecompute":   nil,
}

func init() {
	kloud = kite.New("kloud", "0.0.1")
	kloud.Config.DisableAuthentication = true
	kloud.Config.Port = 3636

	kloud.HandleFunc("build", build)
	kloud.HandleFunc("start", start)
	kloud.HandleFunc("stop", stop)
	kloud.HandleFunc("restart", restart)
	kloud.HandleFunc("destroy", destroy)
	kloud.HandleFunc("info", info)
	// kloud.HandleFunc("resizeDisk", info)
	// kloud.HandleFunc("snapshot", info)

	go kloud.Run()
	<-kloud.ServerReadyNotify()

	client := kite.New("client", "0.0.1")
	client.Config.DisableAuthentication = true
	remote = client.NewClientString("ws://127.0.0.1:3636")
	err := remote.Dial()
	if err != nil {
		log.Fatal("err")
	}
}

func TestProviders(t *testing.T) {
	for provider, data := range TestProviderData {
		if data == nil {
			color.Yellow("==> %s skipping test. test data is not available.", provider)
			continue
		}

		testlog := func(msg string) {
			// mimick it like packer's own log
			color.Cyan("==> %s: %s", provider, msg)
		}

		testlog("Starting tests")
		testlog("Building image and creating machine")
		bArgs := &buildArgs{
			Provider:   data["provider"].(string),
			Credential: data["credential"].(map[string]interface{}),
			Builder:    data["builder"].(map[string]interface{}),
		}

		resp, err := remote.Tell("build", bArgs)
		if err != nil {
			t.Fatal(err)
		}

		var result digitalocean.DropletInfo
		err = resp.Unmarshal(&result)
		if err != nil {
			t.Fatal(err)
		}

		dropletId := result.Droplet.Id

		cArgs := &controllerArgs{
			Provider:   data["provider"].(string),
			Credential: data["credential"].(map[string]interface{}),
			MachineID:  dropletId,
		}

		testlog("Stopping the machine")
		if _, err := remote.Tell("stop", cArgs); err != nil {
			t.Errorf("stop: %s", err)
		}

		testlog("Starting the machine")
		if _, err := remote.Tell("start", cArgs); err != nil {
			t.Errorf("start: %s", err)
		}

		testlog("Restarting the machine")
		if _, err := remote.Tell("restart", cArgs); err != nil {
			t.Errorf("restart: %s", err)
		}

		testlog("Getting info about the machine")
		if _, err := remote.Tell("info", cArgs); err != nil {
			t.Errorf("info: %s", err)
		}

		testlog("Destroying the machine")
		if _, err := remote.Tell("destroy", cArgs); err != nil {
			t.Errorf("destroy: %s", err)
		}
	}
}

func TestBuild(t *testing.T) {
	t.Skip("To enable this test remove this line")

	for provider, data := range TestProviderData {
		if data == nil {
			color.Yellow("==> %s skipping test. test data is not available.", provider)
			continue
		}

		bArgs := &buildArgs{
			Provider:   data["provider"].(string),
			Credential: data["credential"].(map[string]interface{}),
			Builder:    data["builder"].(map[string]interface{}),
		}

		resp, err := remote.Tell("build", bArgs)
		if err != nil {
			t.Fatal(err)
		}

		var result digitalocean.DropletInfo
		err = resp.Unmarshal(&result)
		if err != nil {
			t.Fatal(err)
		}
	}

}

//
// func TestStart(t *testing.T) {
// 	clientID, apiKey := digitalOceanKeys()
// 	args := &controllerArgs{
// 		Provider: "digitalocean",
// 		Credential: map[string]interface{}{
// 			"client_id": clientID,
// 			"api_key":   apiKey,
// 		},
// 		MachineID: TestDropletId,
// 	}
//
// 	_, err := remote.Tell("start", args)
//
// 	fmt.Printf("\n==== err: %+v\n\n", err)
// }
//
// func TestStop(t *testing.T) {
// 	clientID, apiKey := digitalOceanKeys()
// 	args := &controllerArgs{
// 		Provider: "digitalocean",
// 		Credential: map[string]interface{}{
// 			"client_id": clientID,
// 			"api_key":   apiKey,
// 		},
// 		MachineID: TestDropletId,
// 	}
//
// 	_, err := remote.Tell("stop", args)
//
// 	fmt.Printf("\n==== err: %+v\n\n", err)
// }
//
// func TestRestart(t *testing.T) {
// 	clientID, apiKey := digitalOceanKeys()
// 	args := &controllerArgs{
// 		Provider: "digitalocean",
// 		Credential: map[string]interface{}{
// 			"client_id": clientID,
// 			"api_key":   apiKey,
// 		},
// 		MachineID: TestDropletId,
// 	}
//
// 	_, err := remote.Tell("restart", args)
//
// 	fmt.Printf("\n==== err: %+v\n\n", err)
// }
//
// func TestInfo(t *testing.T) {
// 	clientID, apiKey := digitalOceanKeys()
// 	args := &controllerArgs{
// 		Provider: "digitalocean",
// 		Credential: map[string]interface{}{
// 			"client_id": clientID,
// 			"api_key":   apiKey,
// 		},
// 		MachineID: TestDropletId,
// 	}
//
// 	for provider, data := range TestProviderData {
//
// 	}
//
// 	resp, err := remote.Tell("info", args)
// 	if err != nil {
// 		t.Fatal(err)
// 	}
//
// 	var result Droplet
// 	err = resp.Unmarshal(&result)
// 	if err != nil {
// 		t.Fatal(err)
// 	}
//
// 	fmt.Printf("result %+v\n", result)
// }
