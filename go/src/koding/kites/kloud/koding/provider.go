package koding

import (
	"errors"

	"github.com/koding/kloud/api/openstack"
	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"

	"github.com/koding/logging"
)

var (
	DefaultImageName = "Ubuntu 14.04 LTS (Trusty Tahr) (PVHVM)"
	DefaultImageId   = "bb02b1a3-bc77-4d17-ab5b-421d89850fca"

	// id: 2 name: 512MB Standard Instance cpu: 1 ram: 512 disk: 20
	DefaultFlavorId = "2"

	RACKSPACE_USERNAME = "kodinginc"
	RACKSPACE_PASSWORD = "frjJapvap3Ox!Uvk"
	RACKSPACE_API_KEY  = "96d6388ccb936f047fd35eb29c36df17"
	authURL            = "https://identity.api.rackspacecloud.com/v2.0"

	kodingCredential = map[string]interface{}{
		"username": RACKSPACE_USERNAME,
		"apiKey":   RACKSPACE_API_KEY,
	}
)

const (
	ProviderName = "koding"
)

type Provider struct {
	Log  logging.Logger
	Push func(string, int, machinestate.State)
}

func (p *Provider) NewClient(opts *protocol.MachineOptions) (*openstack.Openstack, error) {
	osClient, err := openstack.New(authURL, "rackspace", kodingCredential, opts.Builder)
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

func (p *Provider) Name() string {
	return ProviderName
}

func (p *Provider) Build(opts *protocol.MachineOptions) (*protocol.ProviderArtifact, error) {
	return nil, nil
}

func (p *Provider) Start(opts *protocol.MachineOptions) (*protocol.ProviderArtifact, error) {
	return nil, nil
}

func (p *Provider) Stop(opts *protocol.MachineOptions) error {
	return nil
}

func (p *Provider) Restart(opts *protocol.MachineOptions) error {
	return nil
}

func (p *Provider) Destroy(opts *protocol.MachineOptions) error {
	return nil
}

func (p *Provider) Info(opts *protocol.MachineOptions) (*protocol.InfoArtifact, error) {
	return nil, nil
}
