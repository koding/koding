package openstack

import (
	"errors"
	"fmt"

	os "koding/kites/kloud/api/openstack"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"

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

	PublicKey  string
	PrivateKey string
	KeyName    string
}

func (p *Provider) Name() string {
	return p.ProviderName
}

func (p *Provider) NewClient(m *protocol.Machine) (*OpenstackClient, error) {
	username := m.Builder["username"].(string)

	o := &OpenstackClient{
		Log: p.Log,
		Push: func(msg string, percentage int, state machinestate.State) {
			p.Log.Info("%s - %s ==> %s", m.Id, username, msg)

			m.Eventer.Push(&eventer.Event{
				Message:    msg,
				Status:     state,
				Percentage: percentage,
			})
		},
	}

	var err error
	o.Openstack, err = os.New(p.AuthURL, p.ProviderName, m.Credential, m.Builder)
	if err != nil {
		return nil, fmt.Errorf("openstack err: %s", err)
	}

	// For now we assume that every client deploys this one particular key,
	// however we can easily override it from the `m` data (mongodb) and
	// replace it with user's own key.

	// needed to deploy during build
	o.Builder.KeyName = p.KeyName

	// needed to create the keypair if it doesn't exist
	o.Builder.PublicKey = p.PublicKey
	o.Builder.PrivateKey = p.PrivateKey

	return o, nil
}

func (p *Provider) Build(m *protocol.Machine) (*protocol.Artifact, error) {
	o, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	instanceName := m.Builder["instanceName"].(string)

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

func (p *Provider) Cancel(m *protocol.Machine) error {
	return nil
}

func (p *Provider) Start(m *protocol.Machine) (*protocol.Artifact, error) {
	o, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	return o.Start()
}

func (p *Provider) Stop(m *protocol.Machine) error {
	o, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return o.Stop()
}

func (p *Provider) Restart(m *protocol.Machine) error {
	o, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return o.Restart()
}

func (p *Provider) Destroy(m *protocol.Machine) error {
	o, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return o.Destroy()
}

func (p *Provider) Info(m *protocol.Machine) (*protocol.InfoArtifact, error) {
	o, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	return o.Info()
}

func (p *Provider) Resize(m *protocol.Machine) (*protocol.Artifact, error) {
	return nil, errors.New("resize is not supported")
}

func (p *Provider) Reinit(m *protocol.Machine) (*protocol.Artifact, error) {
	return nil, errors.New("reinitialize is not supported")
}
