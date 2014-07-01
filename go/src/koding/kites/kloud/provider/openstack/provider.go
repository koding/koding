package openstack

import (
	"errors"
	"fmt"
	os "koding/kites/kloud/api/openstack"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"
	"strings"
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

	imageId := DefaultImageId
	if opts.ImageName != "" {
		imageId = opts.ImageName
	}

	if opts.InstanceName == "" {
		return nil, errors.New("dropletName is empty")
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

	// check if the flavor does exist
	flavors, err := o.Flavors()
	if err != nil {
		return nil, err
	}

	if !flavors.Has(DefaultFlavorId) {
		return nil, fmt.Errorf("Flavor id '%s' doesn't exist", DefaultFlavorId)
	}

	newServer := gophercloud.NewServer{
		Name:        opts.InstanceName,
		ImageRef:    imageId,
		FlavorRef:   DefaultFlavorId,
		KeyPairName: key.Name,
	}

	p.Push(fmt.Sprintf("Creating server %s", opts.InstanceName), 20, machinestate.Building)
	resp, err := o.Client.CreateServer(newServer)
	if err != nil {
		return nil, fmt.Errorf("Error creating server: %s", err)
	}

	for {
		server, err := o.Client.ServerById(resp.Id)
		if err != nil {
			return nil, err
		}

		p.Push(fmt.Sprintf("Checking server for ready: %s", opts.InstanceName), 40, machinestate.Building)
		if statusToState(server.Status) == machinestate.Running {
			pretty.Println("server", server)
			break
		}

		time.Sleep(time.Second * 3)
	}

	return nil, errors.New("not supported yet")

	// return &protocol.BuildResponse{
	// 	IpAddress:    droplet.IpAddress,
	// 	InstanceName: dropletName, // we don't use droplet.Name because it might have the cached name
	// 	InstanceId:   droplet.Id,
	// }, nil

}

func (p *Provider) Start(opts *protocol.MachineOptions) error {
	return errors.New("Stop is not supported.")
}

func (p *Provider) Stop(opts *protocol.MachineOptions) error {
	return errors.New("Stop is not supported.")
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

// statusToState converts a rackspacke status to a sensible machinestate.State
// format
func statusToState(status string) machinestate.State {
	status = strings.ToLower(status)

	switch status {
	case "active":
		return machinestate.Running
	case "suspended":
		return machinestate.Stopped
	case "build", "rebuild":
		return machinestate.Building
	case "deleted":
		return machinestate.Terminated
	case "hard_reboot", "reboot":
		return machinestate.Rebooting
	case "migrating", "password", "resize":
		return machinestate.Updating
	default:
		return machinestate.Unknown
	}
}
