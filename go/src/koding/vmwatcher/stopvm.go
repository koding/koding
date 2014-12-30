package main

import (
	"fmt"
	"log"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
)

// request arguments
type stopArgs struct {
	MachineId string `json:"machineId"`
}

// response type
type stopResult struct {
	State   string `json:"state"`
	EventId string `json:"eventId"`
}

func stopVm(machineId string) error {
	// create new kite
	k := kite.New(WorkerName, WorkerVersion)
	config, err := config.Get()
	if err != nil {
		log.Fatal(err)
	}

	// set skeleton config
	k.Config = config

	// create a new connection to the cloud
	client := k.NewClient(KloudAddr)
	client.Auth = &kite.Auth{
		Type: "kloudctl",
		Key:  KloudSecretKey,
	}

	// dial the kloud address
	if err := client.DialTimeout(time.Second * 10); err != nil {
		log.Fatal(err)
	}

	// call the `stop` method with the stopArgs parameter
	var result stopResult
	resp, err := client.Tell("stop", &stopArgs{MachineId: machineId})
	if err != nil {
		return err
	}

	// unmarshal the response
	if err := resp.Unmarshal(&result); err != nil {
		return err
	}

	fmt.Printf("result %+v\n", result)

	return nil
}
