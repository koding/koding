package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"testing"

	"github.com/koding/kite"
)

var (
	kloud        *kite.Kite
	remote       *kite.Client
	flagTestData = flag.String("testdata", "", "Inject test data to build method.")
)

func init() {
	kloud = kite.New("kloud", "0.0.1")
	kloud.Config.DisableAuthentication = true
	kloud.Config.Port = 3636

	kloud.HandleFunc("build", build)
	kloud.HandleFunc("start", start)
	kloud.HandleFunc("stop", stop)
	kloud.HandleFunc("restart", restart)
	kloud.HandleFunc("destroy", destroy)

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

func TestBuild(t *testing.T) {
	t.Skip("To enable this test remove this line")
	args := &buildArgs{}
	var clientID string
	var apiKey string

	if clientID = os.Getenv("DIGITALOCEAN_CLIENT_ID"); clientID == "" {
		clientID = "2d314ba76e8965c451f62d7e6a4bc56f"
	}

	if apiKey = os.Getenv("DIGITALOCEAN_API_KEY"); apiKey == "" {
		apiKey = "4c88127b50c0c731aeb5129bdea06deb"
	}

	if *flagTestData != "" {
		data, err := ioutil.ReadFile(*flagTestData)
		if err != nil {
			t.Fatal(err)
		}

		err = json.Unmarshal(data, args)
		if err != nil {
			t.Fatal(err)
		}

	} else {
		args = &buildArgs{
			Provider: "digitalocean",
			Credential: map[string]interface{}{
				"client_id": clientID,
				"api_key":   apiKey,
			},
			Builder: map[string]interface{}{
				"type":          "digitalocean",
				"client_id":     clientID,
				"api_key":       apiKey,
				"image":         "ubuntu-13-10-x64",
				"region":        "ams2",
				"size":          "512mb",
				"snapshot_name": "koding-{{timestamp}}",
			},
		}
	}

	_, err := remote.Tell("build", args)

	fmt.Printf("\n==== err: %+v\n\n", err)
}

func digitalOceanKeys() (string, string) {
	var clientID string
	var apiKey string

	if clientID = os.Getenv("DIGITALOCEAN_CLIENT_ID"); clientID == "" {
		clientID = "2d314ba76e8965c451f62d7e6a4bc56f"
	}

	if apiKey = os.Getenv("DIGITALOCEAN_API_KEY"); apiKey == "" {
		apiKey = "4c88127b50c0c731aeb5129bdea06deb"
	}

	return clientID, apiKey
}

func TestStart(t *testing.T) {
	clientID, apiKey := digitalOceanKeys()
	args := &controllerArgs{
		Provider: "digitalocean",
		Credential: map[string]interface{}{
			"client_id": clientID,
			"api_key":   apiKey,
		},
		MachineID: 1657055,
	}

	_, err := remote.Tell("start", args)

	fmt.Printf("\n==== err: %+v\n\n", err)
}

func TestStop(t *testing.T) {
	clientID, apiKey := digitalOceanKeys()
	args := &controllerArgs{
		Provider: "digitalocean",
		Credential: map[string]interface{}{
			"client_id": clientID,
			"api_key":   apiKey,
		},
		MachineID: 1657055,
	}

	_, err := remote.Tell("stop", args)

	fmt.Printf("\n==== err: %+v\n\n", err)
}

func TestRestart(t *testing.T) {
	clientID, apiKey := digitalOceanKeys()
	args := &controllerArgs{
		Provider: "digitalocean",
		Credential: map[string]interface{}{
			"client_id": clientID,
			"api_key":   apiKey,
		},
		MachineID: 1657055,
	}

	_, err := remote.Tell("restart", args)

	fmt.Printf("\n==== err: %+v\n\n", err)
}
