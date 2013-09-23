package main

import (
	"flag"
	"koding/newkite/kite"
	"koding/newkite/protocol"
)

type VM struct{}

var (
	port = flag.String("port", "4000", "port to bind itself")
	ip   = flag.String("ip", "0.0.0.0", "ip to bind itself")
)

func main() {
	flag.Parse()
	o := &protocol.Options{
		LocalIP:  *ip,
		Username: "fatih",
		Kitename: "provision",
		Version:  "1",
		Port:     *port,
	}

	methods := map[string]interface{}{
		"vm.start":          VM.Start,
		"vm.shutdown":       VM.Shutdown,
		"vm.stop":           VM.Stop,
		"vm.reinitialize":   VM.Reinitialize,
		"vm.info":           VM.Info,
		"vm.resizeDisk":     VM.ResizeDisk,
		"vm.createSnaphost": VM.CreateSnaphost,
	}

	k := kite.New(o, new(VM), methods)
	k.Start()
}

func (VM) Start(r *protocol.KiteDnodeRequest, result *map[string]interface{}) error {
	return nil
}

func (VM) Shutdown(r *protocol.KiteDnodeRequest, result *map[string]interface{}) error {
	return nil
}

func (VM) Stop(r *protocol.KiteDnodeRequest, result *map[string]interface{}) error {
	return nil
}

func (VM) Info(r *protocol.KiteDnodeRequest, result *map[string]interface{}) error {
	return nil
}

func (VM) Reinitialize(r *protocol.KiteDnodeRequest, result *map[string]interface{}) error {
	return nil
}

func (VM) CreateSnaphost(r *protocol.KiteDnodeRequest, result *map[string]interface{}) error {
	return nil
}

func (VM) ResizeDisk(r *protocol.KiteDnodeRequest, result *map[string]interface{}) error {
	return nil
}
