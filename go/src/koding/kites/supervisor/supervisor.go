// +build linux

package main

import (
	"errors"
	"flag"
	"fmt"
	"github.com/caglar10ur/lxc"
	"koding/newkite/kite"
	"koding/newkite/protocol"
)

type Supervisor struct{}

var port = flag.String("port", "4005", "port to bind itself")

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

func (s *Supervisor) Create(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
		Template      string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return errors.New("{ containerName: [string] }")
	}

	err := s.lxcCreate(params.ContainerName, params.Template)
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func (s *Supervisor) Destroy(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return errors.New("{ containerName: [string] }")
	}

	err := s.lxcDestroy(params.ContainerName)
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func (s *Supervisor) Start(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return errors.New("{ containerName: [string] }")
	}

	err := s.lxcStart(params.ContainerName)
	if err != nil {
		return err
	}

	*result = true

	return nil
}

func (s *Supervisor) Stop(r *protocol.KiteDnodeRequest, result *bool) error {
	return nil
}

func (s *Supervisor) Exec(r *protocol.KiteDnodeRequest, result *bool) error {
	return nil
}

func (s *Supervisor) lxcStart(containerName string) error {
	c := lxc.NewContainer(containerName)
	defer lxc.PutContainer(c)

	if err := c.SetDaemonize(); err != nil {
		return fmt.Errorf("ERROR: %s\n", err.Error())
	}

	if err := c.Start(false); err != nil {
		return fmt.Errorf("ERROR: %s\n", err.Error())
	}

	return nil
}

func (s *Supervisor) lxcCreate(containerName, template string) error {
	c := lxc.NewContainer(containerName)
	defer lxc.PutContainer(c)
	return c.Create(template)
}

func (s *Supervisor) lxcDestroy(containerName string) error {
	c := lxc.NewContainer(containerName)
	defer lxc.PutContainer(c)
	return c.Destroy()
}
