package info

import "github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"

type info struct {
	// ProviderName is the name of the machine (vm or otherwise) provider,
	// as identified by the
	ProviderName string `json:"providerName"`
}

// Info implements the klient.info method, returning klient specific
// information about the machine klient is running within.
//
// See also `kite.info`.
func Info(r *kite.Request) (interface{}, error) {
	providerName, err := CheckProvider()
	if err != nil {
		return info{}, err
	}

	i := info{
		ProviderName: providerName.String(),
	}

	return i, nil
}
