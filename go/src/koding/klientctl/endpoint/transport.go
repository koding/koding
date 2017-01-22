package endpoint

import (
	"koding/api"
	"koding/api/apiutil"
	"koding/klientctl/config"
	"koding/klientctl/endpoint/kloud"
)

// Transport builds a socialapi.Transport with kloud.Client
// as an authorization endpoint.
//
// If client is nil, kloud.DefaultClient is used instead.
func Transport(client *kloud.Client) *api.Transport {
	if client == nil {
		client = kloud.DefaultClient
	}

	return &api.Transport{
		AuthFunc: (&apiutil.KloudAuth{
			Kite: client.Transport,
			Storage: &apiutil.Storage{
				Cache: client.Cache(),
			},
		}).Auth,
		Debug: config.Konfig.Debug,
		Log:   kloud.DefaultLog,
	}
}
