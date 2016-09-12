package vagrant

import (
	"errors"
	"net/url"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/vagrantapi"
	"koding/kites/kloud/provider"
	"koding/kites/kloud/stack"

	"golang.org/x/net/context"
)

func init() {
	provider.All["vagrant"] = func(bp *provider.BaseProvider) stack.Provider {
		return &Provider{
			BaseProvider: bp,
		}
	}
}

// TODO(rjeczalik): kloud refactoring notes:
//
//   - create modelhelpers.DB and move function helpers to methods,
//     so it's posible to use it with non-global *mongodb.MongoDB
//     values
//

// Provider implements machine management operations.
type Provider struct {
	*provider.BaseProvider
}

func (p *Provider) Machine(ctx context.Context, id string) (stack.Machine, error) {
	bm, err := p.BaseMachine(ctx, id)
	if err != nil {
		return nil, err
	}

	// TODO(rjeczalik): move decoding provider-specific metadata to BaseMachine.
	var mt Meta
	if err := modelhelper.BsonDecode(bm.Meta, &mt); err != nil {
		return nil, err
	}

	if err := mt.Valid(); err != nil {
		return nil, err
	}

	// TODO(rjeczalik): move decoding provider-specific credential to BaseMachine.
	var cred VagrantMeta
	if err := p.FetchCredData(bm, &cred); err != nil {
		return nil, err
	}

	return &Machine{
		BaseMachine: bm,
		Meta:        &mt,
		Cred:        &cred,
		Vagrant: &vagrantapi.Klient{
			Kite:  bm.Kite,
			Log:   bm.Log.New("vagrantapi"),
			Debug: bm.Debug,
		},
	}, nil
}

func (p *Provider) tunnelURL() (*url.URL, error) {
	if p.TunnelURL == "" {
		return nil, errors.New("no tunnel URL provided")
	}

	u, err := url.Parse(p.TunnelURL)
	if err != nil {
		return nil, err
	}

	u.Path = "/kite"

	return u, nil
}
