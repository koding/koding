package amazon

import (
	"fmt"

	aws "koding/kites/kloud/api/amazon"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
	"github.com/koding/logging"
)

type Provider struct {
	Log  logging.Logger
	Push func(string, int, machinestate.State)
}

func (p *Provider) NewClient(opts *protocol.Machine) (*AmazonClient, error) {
	username := opts.Builder["username"].(string)

	a := &AmazonClient{
		Log: p.Log,
		Push: func(msg string, percentage int, state machinestate.State) {
			p.Log.Info("%s - %s ==> %s", opts.MachineId, username, msg)

			opts.Eventer.Push(&eventer.Event{
				Message:    msg,
				Status:     state,
				Percentage: percentage,
			})
		},
	}

	var err error
	a.Amazon, err = aws.New(opts.Credential, opts.Builder)
	if err != nil {
		return nil, fmt.Errorf("amazon err: %s", err)
	}

	return a, nil
}

func (p *Provider) Name() string {
	return "amazon"
}

func (p *Provider) Build(opts *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	instanceName := opts.Builder["instanceName"].(string)

	return a.Build(instanceName)
}

func (p *Provider) Cancel(opts *protocol.Machine) error {
	return nil
}

func (p *Provider) Start(opts *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return a.Start()
}

func (p *Provider) Stop(opts *protocol.Machine) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return a.Stop()
}

func (p *Provider) Restart(opts *protocol.Machine) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return a.Restart()
}

func (p *Provider) Destroy(opts *protocol.Machine) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return a.Destroy()
}

func (p *Provider) Info(opts *protocol.Machine) (*protocol.InfoArtifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return a.Info()
}
