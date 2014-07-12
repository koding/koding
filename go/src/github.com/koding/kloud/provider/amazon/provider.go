package amazon

import (
	"errors"

	aws "github.com/koding/kloud/api/amazon"
	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/koding/logging"
)

var (
	// Ubuntu 14.04 EBS backed, amd64, HVM
	DefaultAMI = "ami-a6926dce"

	// Ubuntu 14.0.4 EBS backed, amd64,  PV
	// DefaultAMI = "ami-80778be8"

	ErrNotSupported = errors.New("method not supported")
)

type Provider struct {
	Log  logging.Logger
	Push func(string, int, machinestate.State)
}

func (p *Provider) NewClient(opts *protocol.MachineOptions) (*AmazonClient, error) {
	a := &AmazonClient{
		Log: p.Log,
		Push: func(msg string, percentage int, state machinestate.State) {
			p.Log.Info("%s - %s ==> %s", opts.MachineId, opts.Username, msg)

			opts.Eventer.Push(&eventer.Event{
				Message:    msg,
				Status:     state,
				Percentage: percentage,
			})
		},
		Deploy: opts.Deploy,
	}

	var err error
	a.Amazon, err = aws.New(opts.Credential, opts.Builder)
	if err != nil {
		return nil, err
	}

	return a, nil
}

func (p *Provider) Name() string {
	return "amazon"
}

func (p *Provider) Build(opts *protocol.MachineOptions) (*protocol.Artifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	if opts.InstanceName == "" {
		return nil, errors.New("server name is empty")
	}

	return a.Build(opts.InstanceName)
}

func (p *Provider) Start(opts *protocol.MachineOptions) (*protocol.Artifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return a.Start()
}

func (p *Provider) Stop(opts *protocol.MachineOptions) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return a.Stop()
}

func (p *Provider) Restart(opts *protocol.MachineOptions) error {
	return ErrNotSupported
}

func (p *Provider) Destroy(opts *protocol.MachineOptions) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return a.Destroy()
}

func (p *Provider) Info(opts *protocol.MachineOptions) (*protocol.InfoArtifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return a.Info()
}
