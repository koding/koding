// +build linux

package main

import (
	"errors"
	"flag"
	"fmt"
	"github.com/caglar10ur/lxc"
	"koding/newkite/kite"
	"koding/newkite/protocol"
	"strings"
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
		"vm.run":     "Run",
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

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" || params.Template == "" {
		return errors.New("{ containerName: [string], template: [string] }")
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

	fmt.Println("no err")

	*result = true

	return nil
}

func (s *Supervisor) Stop(r *protocol.KiteDnodeRequest, result *bool) error {
	return nil
}

func (s *Supervisor) Run(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
		Command       string
	}
	if r.Args.Unmarshal(&params) != nil {
		return errors.New("excepted [string]")
	}

	err := s.lxcRun(params.ContainerName, params.Command)
	if err != nil {
		return err
	}

	return nil
}

func (s *Supervisor) lxcRun(containerName, command string) error {
	fmt.Printf("running '%s' on '%s'\n", command, containerName)

	c := lxc.NewContainer(containerName)
	defer lxc.PutContainer(c)

	fmt.Printf("AttachRunShell\n")
	if err := c.AttachRunShell(); err != nil {
		fmt.Errorf("ERROR: %s\n", err.Error())
	}

	args := strings.Split(command, " ")

	fmt.Printf("AttachRunCommand\n", args)
	if err := c.AttachRunCommand(args...); err != nil {
		fmt.Errorf("ERROR: %s\n", err.Error())
	}

	return nil
}

func (s *Supervisor) lxcStart(containerName string) error {
	fmt.Println("starting ", containerName)

	c := lxc.NewContainer(containerName)
	defer lxc.PutContainer(c)

	err := c.SetDaemonize()
	if err != nil {
		return fmt.Errorf("ERROR: %s\n", err.Error())
	}

	err = c.Start(false)
	if err != nil {
		return fmt.Errorf("ERROR: %s\n", err.Error())
	}

	return nil
}

func (s *Supervisor) lxcCreate(containerName, template string) error {
	fmt.Printf("creating vm '%s' with template '%s'\n", containerName, template)

	c := lxc.NewContainer(containerName)
	defer lxc.PutContainer(c)
	return c.Create(template)
}

func (s *Supervisor) lxcDestroy(containerName string) error {
	fmt.Println("destroying ", containerName)

	c := lxc.NewContainer(containerName)
	defer lxc.PutContainer(c)
	return c.Destroy()
}
