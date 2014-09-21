package amazon

import (
	"errors"
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

func (p *Provider) NewClient(m *protocol.Machine) (*AmazonClient, error) {
	a := &AmazonClient{
		Log: p.Log,
		Push: func(msg string, percentage int, state machinestate.State) {
			p.Log.Info("%s - %s ==> %s", m.Id, m.Username, msg)

			m.Eventer.Push(&eventer.Event{
				Message:    msg,
				Status:     state,
				Percentage: percentage,
			})
		},
	}

	var err error
	a.Amazon, err = aws.New(m.Credential, m.Builder)
	if err != nil {
		return nil, fmt.Errorf("amazon err: %s", err)
	}

	return a, nil
}

func (p *Provider) Name() string {
	return "amazon"
}

func (p *Provider) Build(m *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	instanceName := m.Builder["instanceName"].(string)

	return a.Build(instanceName)
}

func (p *Provider) Cancel(m *protocol.Machine) error {
	return nil
}

func (p *Provider) Start(m *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	return a.Start(true)
}

func (p *Provider) Stop(m *protocol.Machine) error {
	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return a.Stop(true)
}

func (p *Provider) Restart(m *protocol.Machine) error {
	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return a.Restart()
}

func (p *Provider) Destroy(m *protocol.Machine) error {
	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return a.Destroy()
}

func (p *Provider) Info(m *protocol.Machine) (*protocol.InfoArtifact, error) {
	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	return a.Info()
}

func (p *Provider) Resize(m *protocol.Machine) (*protocol.Artifact, error) {
	return nil, errors.New("resize is not supported")
}

func (p *Provider) Reinitialize(m *protocol.Machine) (*protocol.Artifact, error) {
	return nil, errors.New("reinitialize is not supported")
}
