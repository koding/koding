package openstack

import (
	"errors"
	os "koding/kites/kloud/api/openstack"
	"koding/kites/kloud/eventer"
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

func (p *Provider) NewClient(opts *protocol.MachineOptions) (*os.Openstack, error) {
	osClient, err := os.New(p.AuthURL, p.ProviderName, opts.Credential, opts.Builder)
	if err != nil {
		return nil, err
	}

	if opts.Eventer == nil {
		return nil, errors.New("Eventer is not defined.")
	}

	p.Push = func(msg string, percentage int, state machinestate.State) {
		p.Log.Info("%s - %s ==> %s", opts.MachineId, opts.Username, msg)

		opts.Eventer.Push(&eventer.Event{
			Message:    msg,
			Status:     state,
			Percentage: percentage,
		})
	}

	return osClient, nil
}

func (p *Provider) Build(opts *protocol.MachineOptions) (*protocol.BuildResponse, error) {
	_, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return nil, errors.New("not supported yet.")
}

func (p *Provider) Start(opts *protocol.MachineOptions) error {
	return errors.New("build is not supported yet.")
}

func (p *Provider) Stop(opts *protocol.MachineOptions) error {
	return errors.New("build is not supported yet.")
}

func (p *Provider) Restart(opts *protocol.MachineOptions) error {
	return errors.New("build is not supported yet.")
}

func (p *Provider) Destroy(opts *protocol.MachineOptions) error {
	return errors.New("build is not supported yet.")
}

func (p *Provider) Info(opts *protocol.MachineOptions) (*protocol.InfoResponse, error) {
	// authentication is done inside this package
	_, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return nil, errors.New("not supported yet.")
}
