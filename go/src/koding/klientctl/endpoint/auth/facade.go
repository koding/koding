package auth

import (
	"net/url"
	"os"

	"koding/kites/config"
	"koding/kites/config/configstore"
	"koding/kites/kloud/stack"
	conf "koding/klientctl/config"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/kontrol"
	"koding/klientctl/endpoint/team"
	"koding/klientctl/helper"

	"github.com/koding/logging"
)

// Facade provides a mean for auth.Client to create
// and work with new configuration in konfig.bolt
// database.
//
// It allows for switching between multiple
// configurations, which may use conflicting
// sessions (e.g. kite.key file created with
// different Kontrol keys).
type Facade struct {
	*Client

	Konfig *config.Konfig
	Kloud  *kloud.Client
	Team   *team.Client
	Log    logging.Logger

	force bool // whether force new session; if true, overrides LoginOptions.Force
}

// FacadeOptions is used to create new Facade value.
type FacadeOptions struct {
	Base *url.URL
	Log  logging.Logger
}

// NewFacade gives new Facade value.
//
// It returns non-nil error if it is unable to
// create new configuration out of the provided
// options.
func NewFacade(opts *FacadeOptions) (*Facade, error) {
	k, force, err := newKonfig(opts.Base)
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
		Log:   opts.Log,
		force: force,
	}, nil
}

// Login authorizes with Koding in order to obtain:
//
//   - kite.key for use with Kontrol / Terraformer / Kloud / Klient kites
//   - ClientID for use with SocialAPI / remote.api
//
func (f *Facade) Login(opts *LoginOptions) (*stack.PasswordLoginResponse, error) {
	newLogin := opts.Force || f.force

	if !newLogin {
		// If we already own a valid kite.key, it means we were already
		// authenticated and we just call kloud using kite.key authentication.
		err := f.Kloud.Transport.(stack.Validator).Valid()
		f.log().Debug("auth: transport test: %s", err)

		newLogin = err != nil
	}

	var kiteKey string

	if opts.Token != "" {
		// NOTE(rjeczalik): Backward compatibility with token-based authentication.
		//
		// The workflow:
		//
		//   - call Kontrol's "registerMachine" in order to obtain kite.key
		//   - using the kite.key call Kloud's "auth.login" in order to obtain
		//     ClientID for remote.api
		//
		// This should be removed once we get rid of temporary token-based auth
		// (otaToken, do not confuse with not kite.key's tokenAuth).
		resp, err := f.Client.Login(opts)
		if err != nil {
			return nil, err
		}

		if kt, ok := f.Kloud.Transport.(*kloud.KiteTransport); ok {
			kt.SetKiteKey(resp.KiteKey)
		}

		opts.Token = ""
		kiteKey = resp.KiteKey
		f.Konfig.KiteKey = resp.KiteKey
	} else if newLogin {
		if err := opts.AskUserPass(); err != nil {
			return nil, err
		}
	}

	if opts.Team == "" {
		var err error
		opts.Team, err = helper.Ask("%sTeam name [%s]: ", opts.Prefix, f.Team.Used().Name)
		if err != nil {
			return nil, err
		}

		if opts.Team == "" {
			opts.Team = f.Team.Used().Name
		}
	}

	resp, err := f.Client.Login(opts)
	if err != nil {
		return nil, err
	}

	if kiteKey == "" {
		kiteKey = resp.KiteKey
	}

	if kiteKey != "" {
		f.Konfig.KiteKey = kiteKey
		if resp.Metadata != nil {
			fixKlientEndpoint(f.Konfig.Endpoints)

			base := f.Konfig.Endpoints.Koding // do not overwrite baseurl
			f.Konfig.Endpoints = resp.Metadata.Endpoints
			f.Konfig.Endpoints.Koding = base
		}

		if err := configstore.Use(f.Konfig); err != nil {
			return nil, err
		}

		if kt, ok := f.Kloud.Transport.(*kloud.KiteTransport); ok {
			kt.SetKiteKey(kiteKey)
		}
	}

	if resp.GroupName != "" {
		f.Team.Use(&team.Team{Name: resp.GroupName})
	}

	return resp, nil
}

func (f *Facade) Close() error {
	return nonil(
		f.Team.Close(),
		f.Client.Close(),
		f.Kloud.Close(),
	)
}

func (f *Facade) log() logging.Logger {
	if f.Log != nil {
		return f.Log
	}
	return kloud.DefaultLog
}

func newKonfig(base *url.URL) (*config.Konfig, bool, error) {
	force := false
	newID := config.ID(base.String())

	if k, err := configstore.Used(); err == nil {
		force = k.ID() != newID
	}

	k, ok := configstore.List()[newID]
	if !ok {
		k = &config.Konfig{
			Endpoints: &config.Endpoints{
				Koding: config.NewEndpointURL(base),
			},
			Debug: os.Getenv("KD_DEBUG") == "1",
		}
	}

	if err := configstore.Use(k); err != nil {
		return nil, false, err
	}

	return k, force, nil
}

// fixKlientEndpoint fixes klient latest endpoint - kloud always installs
// klient from development/production channels, however kd needs to use
// managed/devmanaed ones.
//
// This is a hack that eventually needs to be removed.
func fixKlientEndpoint(e *config.Endpoints) {
	if !e.KlientLatest.IsNil() {
		e.KlientLatest = config.ReplaceCustomEnv(e.KlientLatest, conf.Environments.Env,
			conf.Environments.KlientEnv)
	}
}
