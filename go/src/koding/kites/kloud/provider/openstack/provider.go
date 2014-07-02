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
	o, err := p.NewClient(opts)
	if err != nil {
		return err
	}
	p.Push("Starting machine", 10, machinestate.Stopping)

	// check if our key exist
	key, err := o.ShowKey(protocol.KeyName)
	if err != nil {
		return err
	}

	// key doesn't exist, create a new one
	if key.Name == "" {
		key, err = o.CreateKey(protocol.KeyName, protocol.PublicKey)
		if err != nil {
			return err
		}
	}

	p.Push(fmt.Sprintf("Checking if backup image '%s' exists", o.Builder.InstanceName), 20, machinestate.Starting)
	images, err := o.Images()
	if err != nil {
		return err
	}

	image, err := images.ImageByName(o.Builder.InstanceName)
	if err != nil {
		return err
	}

	newServer := gophercloud.NewServer{
		Name:        o.Builder.InstanceName,
		ImageRef:    image.Id,
		FlavorRef:   o.Builder.Flavor,
		KeyPairName: key.Name,
	}

	p.Push(fmt.Sprintf("Starting server %s", opts.InstanceName), 30, machinestate.Starting)
	resp, err := o.Client.CreateServer(newServer)
	if err != nil {
		return fmt.Errorf("Error creating server: %s", err)
	}

	// eventer percentages
	start := 35
	finish := 60

	// store successfull result here
	var server *gophercloud.Server

	stateFunc := func() (machinestate.State, error) {
		p.Push("Waiting for machine to be ready", start, machinestate.Starting)
		server, err = o.Client.ServerById(resp.Id)
		if err != nil {
			return 0, err
		}

		if start < finish {
			start += 2
		}

		return statusToState(server.Status), nil
	}

	startServer := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Running,
		Timeout:      5 * time.Minute,
		Interval:     2 * time.Second,
	}

	if err := startServer.Wait(); err != nil {
		return err
	}

	// TODO: update instanceId in storage with the new server ID

	// now delete our backup image, we don't need it anymore
	p.Push(fmt.Sprintf("Deleting backup image %s - %s", image.Name, image.Id), 80, machinestate.Starting)
	if err := o.Client.DeleteImageById(image.Id); err != nil {
		return err
	}

	return nil
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

	stateFunc := func() (machinestate.State, error) {
		server, err := o.Server()
		if err != nil {
			return 0, err
		}

		// and empty taks means the image creating and uploading task has been
		// finished, now we can move on to the next step.
		if server.OsExtStsTaskState == "" {
			return machinestate.Stopping, nil
		}

		p.Push(fmt.Sprintf("Taking image '%s' of machine, curent state: %s", respId, server.OsExtStsTaskState), 60, machinestate.Stopping)
		return statusToState(server.Status), nil
	}

	imageCreation := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Stopping,
		Timeout:      5 * time.Minute,
		Interval:     3 * time.Second,
	}

	// wait until we finished with our task
	if err := imageCreation.Wait(); err != nil {
		return err
	}

	p.Push(fmt.Sprintf("Deleting server: %s", o.Id()), 50, machinestate.Stopping)
	if err := o.Client.DeleteServerById(o.Id()); err != nil {
		return err
	}

	stateFunc = func() (machinestate.State, error) {
		p.Push("Waiting for machine to be deleted", 60, machinestate.Stopping)
		server, err := o.Server()
		if err == os.ErrServerNotFound {
			return machinestate.Stopped, nil
		}

		return statusToState(server.Status), nil
	}

	deleteServer := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Stopped,
		Timeout:      5 * time.Minute,
		Interval:     3 * time.Second,
	}

	return deleteServer.Wait()
}

func (p *Provider) Restart(opts *protocol.MachineOptions) error {
	return errors.New("build is not supported yet.")
}

func (p *Provider) Destroy(opts *protocol.MachineOptions) error {
	return errors.New("build is not supported yet.")
}

func (p *Provider) Info(opts *protocol.MachineOptions) (*protocol.InfoArtifact, error) {
	o, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	p.Log.Debug("Checking for server info: %s", o.Id())
	server := &gophercloud.Server{}
	server, err = o.Server()
	if err == os.ErrServerNotFound {
		p.Log.Debug("Server does not exist, checking if it has a backup image")
		images, err := o.Images()
		if err != nil {
			return nil, err
		}

		if images.HasName(o.Builder.InstanceName) {
			// means the machine was deleted and an image exist that points to it
			p.Log.Debug("Image '%s' does exist, means it's stopped.", o.Builder.InstanceName)
			return &protocol.InfoArtifact{
				State: machinestate.Stopped,
				Name:  o.Builder.InstanceName,
			}, nil

		}

		p.Log.Debug("Image does not exist, returning unknown state.")
		return &protocol.InfoArtifact{
			State: machinestate.Terminated,
			Name:  o.Builder.InstanceName,
		}, nil
	}

	if statusToState(server.Status) == machinestate.Unknown {
		p.Log.Warning("Unknown rackspace status: %s. This needs to be fixed.", server.Status)
	}

	return &protocol.InfoArtifact{
		State: statusToState(server.Status),
		Name:  server.Name,
	}, nil

	return nil, errors.New("not supported yet.")
}
