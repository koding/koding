package koding

import (
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"

	"github.com/koding/logging"
)

const (
	ProviderName = "koding"
)

type Provider struct {
	Log  logging.Logger
	Push func(string, int, machinestate.State)
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
