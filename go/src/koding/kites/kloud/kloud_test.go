package main

import (
	"fmt"
	"log"
	"testing"

	"github.com/koding/kite"
)

var (
	kloud  *kite.Kite
	remote *kite.Client
)

func init() {
	kloud = kite.New("kloud", "0.0.1")
	kloud.Config.DisableAuthentication = true
	kloud.Config.Port = 3636

	kloud.HandleFunc("build", build)

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
	args := &buildArgs{
		Provider:     "digitalocean",
		TemplatePath: "testdata/digitalocean_packer.json",
	}

	_, err := remote.Tell("build", args)

	fmt.Printf("\n==== err: %+v\n\n", err)
}
