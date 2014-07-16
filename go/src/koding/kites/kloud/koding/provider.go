package koding

import (
	"errors"

	aws "github.com/koding/kloud/api/amazon"
	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/provider/amazon"

	"github.com/koding/logging"
)

var (
	// DefaultAMI = "ami-80778be8" // Ubuntu 14.0.4 EBS backed, amd64,  PV
	DefaultAMI          = "ami-a6926dce" // Ubuntu 14.04 EBS backed, amd64, HVM
	DefaultInstanceType = "t2.micro"
	DefaultRegion       = "us-east-1"

	kodingCredential = map[string]interface{}{
		"access_key": "AKIAI6IUMWKF3F4426CA",
		"secret_key": "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",
	}
)

const (
	ProviderName = "koding"
)

type Provider struct {
	Log  logging.Logger
	Push func(string, int, machinestate.State)
}

func (p *Provider) NewClient(opts *protocol.MachineOptions) (*amazon.AmazonClient, error) {
	a := &amazon.AmazonClient{
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

	opts.Builder["region"] = DefaultRegion
	a.Amazon, err = aws.New(kodingCredential, opts.Builder)
	if err != nil {
		return nil, err
	}

	return a, nil
}

func (p *Provider) Name() string {
	return ProviderName
}

func (p *Provider) Build(opts *protocol.MachineOptions) (*protocol.Artifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	if opts.InstanceName == "" {
		return nil, errors.New("server name is empty")
	}

	// Use koding plans instead of those later
	a.Builder.SourceAmi = DefaultAMI
	a.Builder.InstanceType = DefaultInstanceType

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
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return a.Restart()
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
