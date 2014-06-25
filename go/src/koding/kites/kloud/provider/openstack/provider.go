package openstack

import (
	os "koding/kites/kloud/api/openstack"
	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"

	"github.com/koding/logging"
)

const (
	ProviderName = "rackspace" // we use rackspace for no
	AuthURL      = "https://identity.api.rackspacecloud.com/v2.0/tokens"
)

type Provider struct {
	Log      logging.Logger
	SignFunc func(string) (string, string, error)
	Push     func(string, int, machinestate.State)

	Region      string
	Environment string
}

func (p *Provider) Name() string {
	return ProviderName
}

func (p *Provider) Build(opts *protocol.MachineOptions) (*protocol.BuildResponse, error) {
	_, err := os.New(AuthURL, opts.Credential, opts.Builder)
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
