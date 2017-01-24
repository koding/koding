package auth

import (
	"net/url"
	"os"

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
	Log    logging.Logger
}

type FacadeOpts struct {
	Base *url.URL
	Log  logging.Logger
}

func NewFacade(opts *FacadeOpts) (*Facade, error) {
	k, err := newKonfig(opts.Base)
	if err != nil {
		return nil, err
	}

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
		Log: opts.Log,
	}, nil
}

func (f *Facade) Login(opts *LoginOptions) (*stack.PasswordLoginResponse, error) {
	// If we already own a valid kite.key, it means we were already
	// authenticated and we just call kloud using kite.key authentication.
	err := f.Kloud.Transport.(stack.Validator).Valid()

	f.log().Debug("auth: transport test: %s", err)

	if err != nil && opts.Token == "" {
		if err = opts.AskUserPass(); err != nil {
			return nil, err
		}
	}

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

func (f *Facade) log() logging.Logger {
	if f.Log != nil {
		return f.Log
	}
	return kloud.DefaultLog
}

func newKonfig(base *url.URL) (*config.Konfig, error) {
	k, ok := configstore.List()[config.ID(base.String())]
	if !ok {
		k = &config.Konfig{
			Endpoints: &config.Endpoints{
				Koding: config.NewEndpointURL(base),
			},
			Debug: os.Getenv("KD_DEBUG") == "1",
		}
	}

	if err := configstore.Use(k); err != nil {
		return nil, err
	}

	return k, nil
}
