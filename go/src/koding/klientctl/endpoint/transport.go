package endpoint

import (
	"koding/klientctl/endpoint/kloud"
	"koding/socialapi"
	"koding/socialapi/socialkite"
)

// Transport builds a socialapi.Transport with kloud.Client
// as an authorization endpoint.
//
// If client is nil, kloud.DefaultClient is used instead.
func Transport(client *kloud.Client) *socialapi.Transport {
	if client == nil {
		client = kloud.DefaultClient
	}

	return &socialapi.Transport{
		AuthFunc: (&socialkite.KloudAuth{
			Kite: client.Transport,
			Storage: &socialkite.Storage{
				Cache: client.Cache(),
			},
		}).Auth,
	}
}
