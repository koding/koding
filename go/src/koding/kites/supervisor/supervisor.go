package main

import (
	"flag"
	"koding/newkite/kite"
	"koding/newkite/protocol"
)

type Supervisor struct{}

var port = flag.String("port", "4004", "port to bind itself")

func main() {
	flag.Parse()
	options := &protocol.Options{
		PublicIP: "localhost",
		Kitename: "supervisor",
		Version:  "0.0.1",
		Port:     *port,
	}

	methods := map[string]string{
		"vm.create":  "Create",
		"vm.destroy": "Destroy",
		"vm.start":   "Start",
		"vm.stop":    "Stop",
		"exec":       "Exec",
	}

	k := kite.New(options)
	k.AddMethods(new(Supervisor), methods)
	k.Start()
}

func (Supervisor) Create(r *protocol.KiteDnodeRequest, result *bool) error  { return nil }
func (Supervisor) Destroy(r *protocol.KiteDnodeRequest, result *bool) error { return nil }
func (Supervisor) Start(r *protocol.KiteDnodeRequest, result *bool) error   { return nil }
func (Supervisor) Stop(r *protocol.KiteDnodeRequest, result *bool) error    { return nil }
func (Supervisor) Exec(r *protocol.KiteDnodeRequest, result *bool) error    { return nil }
