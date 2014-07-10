package koding

import (
	"errors"

	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/provider/openstack"

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

func (p *Provider) NewClient(opts *protocol.MachineOptions) (*openstack.OpenstackClient, error) {
	o := &openstack.OpenstackClient{
		Log: p.Log,
		Push: func(msg string, percentage int, state machinestate.State) {
			p.Log.Info("%s - %s ==> %s", opts.MachineId, opts.Username, msg)

			opts.Eventer.Push(&eventer.Event{
				Message:    msg,
				Status:     state,
				Percentage: percentage,
			})
		},
		AuthURL:       authURL,
		ProviderName:  "rackspace", //openstack related
		CredentialRaw: kodingCredential,
		BuilderRaw:    opts.Builder,
	}

	if err := o.Initialize(); err != nil {
		return nil, err
	}

	return o, nil
}

func (p *Provider) Name() string {
	return ProviderName
}

func (p *Provider) Build(opts *protocol.MachineOptions) (*protocol.ProviderArtifact, error) {
	client, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	if opts.InstanceName == "" {
		return nil, errors.New("server name is empty")
	}

	imageId := DefaultImageId
	// TODO: prevent this and throw an error in the future
	flavorId := client.Builder.Flavor
	if flavorId == "" {
		flavorId = DefaultFlavorId
	}

	return client.Build(opts.InstanceName, imageId, flavorId)
}

func (p *Provider) Start(opts *protocol.MachineOptions) (*protocol.ProviderArtifact, error) {
	o, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return o.Start()
}

func (p *Provider) Stop(opts *protocol.MachineOptions) error {
	o, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return o.Stop()
}

func (p *Provider) Restart(opts *protocol.MachineOptions) error {
	o, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return o.Restart()
}

func (p *Provider) Destroy(opts *protocol.MachineOptions) error {
	o, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return o.Destroy()
}

func (p *Provider) Info(opts *protocol.MachineOptions) (*protocol.InfoArtifact, error) {
	o, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return o.Info()
}
