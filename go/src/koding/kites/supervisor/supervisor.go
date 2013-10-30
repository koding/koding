// +build linux

package main

import (
	"errors"
	"flag"
	"koding/kites/supervisor/container"
	"koding/newkite/kite"
	"koding/newkite/protocol"
)

type Supervisor struct{}

var (
	port   = flag.String("port", "4005", "port to bind itself")
	vmRoot = "/var/lib/lxc/vmroot"
)

func main() {
	flag.Parse()
	options := &protocol.Options{
		PublicIP: "localhost",
		Kitename: "supervisor",
		Version:  "0.0.1",
		Port:     *port,
	}

	methods := map[string]string{
		"vm.create":   "Create",
		"vm.destroy":  "Destroy",
		"vm.start":    "Start",
		"vm.stop":     "Stop",
		"vm.shutdown": "Shutdown",
		"vm.prepare":  "Prepare",
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

	fmt.Printf("creating vm '%s' with template '%s'\n", c.Name, template)
	c := container.NewContainer(params.ContainerName)
	err := c.Create(params.Template)
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

	fmt.Println("destroying", c.Name)
	c := container.NewContainer(params.ContainerName)
	err := c.Destroy()
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

	fmt.Println("starting", c.Name)
	c := container.NewContainer(params.ContainerName)
	err := c.Start()
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func (s *Supervisor) Stop(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return errors.New("{ containerName: [string] }")
	}

	fmt.Println("stopping", c.Name)
	c := container.NewContainer(params.ContainerName)
	err := c.Stop()
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func (s *Supervisor) Shutdown(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
		Timeout       int
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" || params.Timeout == 0 {
		return errors.New("{ containerName: [string], timeout : [int]}")
	}

	fmt.Println("shutdown", c.Name)
	c := container.NewContainer(params.ContainerName)
	err := c.Shutdown(params.Timeout)
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func (s *Supervisor) Run(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
		Command       string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" || params.Command == "" {
		return errors.New("{ containerName: [string], command : [string]}")
	}

	fmt.Printf("running '%s' on '%s'\n", command, c.Name)
	c := container.NewContainer(params.ContainerName)
	err := c.Run(params.Command)
	if err != nil {
		return err
	}

	return nil
}

func (s *Supervisor) Prepare(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
		HostnameAlias string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" || params.HostnameAlias == "" {
		return errors.New("{ containerName: [string], command : [string]}")
	}

	fmt.Printf("preparing container '%s'\n", c.Name)
	c := container.NewContainer(params.ContainerName)
	err := c.Prepare(params.HostnameAlias)
	if err != nil {
		return err
	}

	return nil
}
