package auth

import (
	"net/url"

	"koding/kites/config"
	"koding/kites/config/configstore"
	"koding/kites/kloud/stack"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/kontrol"
	"koding/klientctl/endpoint/team"

	"github.com/koding/logging"
)

type Facade struct {
	*Client

	Konfig *config.Konfig
	Kloud  *kloud.Client
	Team   *team.Client
}

type FacadeOpts struct {
	Base *url.URL
	Log  logging.Logger
}

func NewFacade(opts *FacadeOpts) *Facade {
	k := newKonfig(opts.Base)

	kloud := &kloud.Client{
		Transport: &kloud.KiteTransport{
			Konfig: k,
			Log:    opts.Log,
		},
	}

	return &Facade{
		Client: &Client{
			Kloud: kloud,
			Kontrol: &kontrol.Client{
				Kloud:  kloud,
				Konfig: k,
			},
		},
		Konfig: k,
		Kloud:  kloud,
		Team: &team.Client{
			Kloud: kloud,
		},
	}

}

func (f *Facade) Login(opts *LoginOptions) (*stack.PasswordLoginResponse, error) {
	resp, err := f.Client.Login(opts)
	if err != nil {
		return nil, err
	}

	if resp.KiteKey != "" {
		f.Konfig.KiteKey = resp.KiteKey
		if resp.Metadata != nil {
			f.Konfig.Endpoints = resp.Metadata.Endpoints
		}

		if err := configstore.Use(f.Konfig); err != nil {
			return nil, err
		}

		if kt, ok := f.Kloud.Transport.(*kloud.KiteTransport); ok {
			kt.SetKiteKey(resp.KiteKey)
		}
	}

	if resp.GroupName != "" {
		f.Team.Use(&team.Team{Name: resp.GroupName})
	}

	return resp, nil

}

func newKonfig(base *url.URL) *config.Konfig {
	k, ok := configstore.List()[config.ID(base.String())]
	if !ok {
		k = &config.Konfig{
			Endpoints: &config.Endpoints{
				Koding: config.NewEndpointURL(base),
			},
		}
	}

	return k
}
