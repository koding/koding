package openstack

import (
	"errors"
	"fmt"
	os "koding/kites/kloud/api/openstack"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"
	"koding/kites/kloud/waitstate"
	"time"

	"github.com/koding/logging"
	"github.com/kr/pretty"
	"github.com/rackspace/gophercloud"
)

var (
	DefaultImageName = "Ubuntu 14.04 LTS (Trusty Tahr) (PVHVM)"
	DefaultImageId   = "bb02b1a3-bc77-4d17-ab5b-421d89850fca"

	// id: 2 name: 512MB Standard Instance cpu: 1 ram: 512 disk: 20
	DefaultFlavorId = "2"
)

type Provider struct {
	Log  logging.Logger
	Push func(string, int, machinestate.State)

	Region       string
	Environment  string
	AuthURL      string
	ProviderName string
}

func (p *Provider) Name() string {
	return p.ProviderName
}

func (p *Provider) NewClient(opts *protocol.MachineOptions) (*os.Openstack, error) {
	osClient, err := os.New(p.AuthURL, p.ProviderName, opts.Credential, opts.Builder)
	if err != nil {
		return nil, err
	}

	if opts.Eventer == nil {
		return nil, errors.New("Eventer is not defined.")
	}

	p.Push = func(msg string, percentage int, state machinestate.State) {
		p.Log.Info("%s - %s ==> %s", opts.MachineId, opts.Username, msg)

		opts.Eventer.Push(&eventer.Event{
			Message:    msg,
			Status:     state,
			Percentage: percentage,
		})
	}

	return osClient, nil
}

func (p *Provider) Build(opts *protocol.MachineOptions) (*protocol.BuildResponse, error) {
	o, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	if opts.InstanceName == "" {
		return nil, errors.New("server name is empty")
	}

	imageId := DefaultImageId
	if opts.ImageName != "" {
		imageId = opts.ImageName
	}

	if o.Builder.SourceImage != "" {
		imageId = o.Builder.SourceImage
	}

	p.Push(fmt.Sprintf("Checking for image availability %s", imageId), 10, machinestate.Building)
	_, err = o.Image(imageId)
	if err != nil {
		return nil, err
	}

	// check if our key exist
	key, err := o.ShowKey(protocol.KeyName)
	if err != nil {
		return nil, err
	}

	// key doesn't exist, create a new one
	if key.Name == "" {
		key, err = o.CreateKey(protocol.KeyName, protocol.PublicKey)
		if err != nil {
			return nil, err
		}
	}

	// TODO: prevent this and throw an error in the future
	flavorId := o.Builder.Flavor
	if flavorId == "" {
		flavorId = DefaultFlavorId
	}

	// check if the flavor does exist
	flavors, err := o.Flavors()
	if err != nil {
		return nil, err
	}

	if !flavors.Has(flavorId) {
		return nil, fmt.Errorf("Flavor id '%s' doesn't exist", DefaultFlavorId)
	}

	newServer := gophercloud.NewServer{
		Name:        opts.InstanceName,
		ImageRef:    imageId,
		FlavorRef:   flavorId,
		KeyPairName: key.Name,
	}

	p.Push(fmt.Sprintf("Creating server %s", opts.InstanceName), 20, machinestate.Building)
	resp, err := o.Client.CreateServer(newServer)
	if err != nil {
		return nil, fmt.Errorf("Error creating server: %s", err)
	}

	// eventer percentages
	start := 25
	finish := 60

	// store successfull result here
	var server *gophercloud.Server

	stateFunc := func() (machinestate.State, error) {
		p.Push("Waiting for machine to be ready", start, machinestate.Building)
		server, err = o.Client.ServerById(resp.Id)
		if err != nil {
			return 0, err
		}

		if start < finish {
			start += 2
		}

		return statusToState(server.Status), nil
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Running,
		Timeout:      5 * time.Minute,
		Interval:     2 * time.Second,
	}

	if err := ws.Wait(); err != nil {
		return nil, err
	}

	return &protocol.BuildResponse{
		IpAddress:    server.AccessIPv4,
		InstanceName: server.Name,
		InstanceId:   server.Id,
	}, nil
}

func (p *Provider) Start(opts *protocol.MachineOptions) error {

	return errors.New("Stop is not supported.")
}

func (p *Provider) Stop(opts *protocol.MachineOptions) error {
	o, err := p.NewClient(opts)
	if err != nil {
		return err
	}
	p.Push("Stopping machine", 10, machinestate.Stopping)

	// create backup name the same as the given instanceName
	backup := gophercloud.CreateImage{
		Name: o.Builder.InstanceName,
	}

	p.Push(fmt.Sprintf("Creating a backup image with name: %s for id: %s",
		backup.Name, o.Id()), 30, machinestate.Stopping)
	respId, err := o.Client.CreateImage(o.Id(), backup)
	if err != nil {
		return err
	}

	fmt.Printf("respId %+v\n", respId)

	p.Push(fmt.Sprintf("Deleting server: %s", o.Id()), 50, machinestate.Stopping)
	if err := o.Client.DeleteServerById(o.Id()); err != nil {
		return err
	}

	stateFunc := func() (machinestate.State, error) {
		p.Push("Waiting for machine to be deleted", 60, machinestate.Stopping)
		server, err := o.Server()
		if err != nil {
			return 0, err
		}

		pretty.Println("server", server)

		return statusToState(server.Status), nil
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Stopped,
		Timeout:      5 * time.Minute,
		Interval:     3 * time.Second,
	}

	return ws.Wait()
}

func (p *Provider) Restart(opts *protocol.MachineOptions) error {
	return errors.New("build is not supported yet.")
}

func (p *Provider) Destroy(opts *protocol.MachineOptions) error {
	return errors.New("build is not supported yet.")
}

func (p *Provider) Info(opts *protocol.MachineOptions) (*protocol.InfoResponse, error) {
	o, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	server, err := o.Server()
	if err != nil {
		return nil, err
	}

	if statusToState(server.Status) == machinestate.Unknown {
		p.Log.Warning("Unknown rackspace status: %s. This needs to be fixed.", server.Status)
	}

	return &protocol.InfoResponse{
		State: statusToState(server.Status),
		Name:  server.Name,
	}, nil

	return nil, errors.New("not supported yet.")
}
