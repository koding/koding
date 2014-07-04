package lxc

import (
	"log"
	"testing"

	"github.com/koding/kite"
)

const (
	ContainerType = "busybox"
	ContainerName = "ankara"
)

var (
	lxc    *kite.Kite
	remote *kite.Client
)

func init() {
	lxc = kite.New("lxc", "0.0.1")
	lxc.Config.DisableAuthentication = true
	lxc.Config.Port = 3636
	lxc.HandleFunc("create", Create)
	lxc.HandleFunc("destroy", Destroy)
	lxc.HandleFunc("start", Start)
	lxc.HandleFunc("stop", Stop)

	go lxc.Run()
	<-lxc.ServerReadyNotify()

	client := kite.New("client", "0.0.1")
	client.Config.DisableAuthentication = true
	remote = client.NewClient("http://127.0.0.1:3636/kite")
	err := remote.Dial()
	if err != nil {
		log.Fatal("err")
	}
}

func TestCreate(t *testing.T) {
	params := CreateParams{
		Name:     ContainerName,
		Template: ContainerType,
	}

	resp, err := remote.Tell("create", params)
	if err != nil {
		t.Fatal(err)
	}

	if !resp.MustBool() {
		t.Fatal("create should return true")
	}
}

func TestStart(t *testing.T) {
	params := ContainerParams{
		Name: ContainerName,
	}

	resp, err := remote.Tell("start", params)
	if err != nil {
		t.Fatal(err)
	}

	if !resp.MustBool() {
		t.Fatal("start should return true")
	}
}

func TestStop(t *testing.T) {
	params := ContainerParams{
		Name: ContainerName,
	}

	resp, err := remote.Tell("stop", params)
	if err != nil {
		t.Fatal(err)
	}

	if !resp.MustBool() {
		t.Fatal("stop should return true")
	}
}

func TestDestroy(t *testing.T) {
	params := ContainerParams{
		Name: ContainerName,
	}

	resp, err := remote.Tell("destroy", params)
	if err != nil {
		t.Fatal(err)
	}

	if !resp.MustBool() {
		t.Fatal("destroy should return true")
	}
}
