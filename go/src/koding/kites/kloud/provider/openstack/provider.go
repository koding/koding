package openstack

import (
	os "koding/kites/kloud/api/openstack"
	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"

	"github.com/koding/logging"
)

type Provider struct {
	Log      logging.Logger
	SignFunc func(string) (string, string, error)
	Push     func(string, int, machinestate.State)

	Region       string
	Environment  string
	AuthURL      string
	ProviderName string
}

func (p *Provider) Name() string {
	return p.ProviderName
}

func (p *Provider) Build(opts *protocol.MachineOptions) (*protocol.BuildResponse, error) {
	_, err := os.New(p.AuthURL, opts.Credential, opts.Builder)
	if err != nil {
		return nil, err
	}

	return nil, nil
}

func (p *Provider) Start(opts *protocol.MachineOptions) error {
	return nil
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

func (p *Provider) Info(opts *protocol.MachineOptions) (*protocol.InfoResponse, error) {
	return nil, nil
}
