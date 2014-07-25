package openstack

import (
	os "github.com/koding/kloud/api/openstack"
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
)

type Provider struct {
	Log  logging.Logger
	Push func(string, int, machinestate.State)

	AuthURL      string
	ProviderName string
}

func (p *Provider) Name() string {
	return p.ProviderName
}

func (p *Provider) NewClient(opts *protocol.MachineOptions) (*OpenstackClient, error) {
	username := opts.Builder["username"].(string)

	o := &OpenstackClient{
		Log: p.Log,
		Push: func(msg string, percentage int, state machinestate.State) {
			p.Log.Info("%s - %s ==> %s", opts.MachineId, username, msg)

			opts.Eventer.Push(&eventer.Event{
				Message:    msg,
				Status:     state,
				Percentage: percentage,
			})
		},
		Deploy: opts.Deploy,
	}

	var err error
	o.Openstack, err = os.New(p.AuthURL, p.ProviderName, opts.Credential, opts.Builder)
	if err != nil {
		return nil, err
	}

	return o, nil
}

func (p *Provider) Build(opts *protocol.MachineOptions) (*protocol.Artifact, error) {
	o, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	instanceName := opts.Builder["instanceName"].(string)

	imageId := DefaultImageId
	if o.Builder.SourceImage != "" {
		imageId = o.Builder.SourceImage
	}

	// TODO: prevent this and throw an error in the future
	flavorId := o.Builder.Flavor
	if flavorId == "" {
		flavorId = DefaultFlavorId
	}

	return o.Build(instanceName, imageId, flavorId)
}

func (p *Provider) Start(opts *protocol.MachineOptions) (*protocol.Artifact, error) {
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
