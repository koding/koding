package kloud

import (
	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/idlock"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/provider/amazon"
	"github.com/koding/kloud/provider/digitalocean"
	"github.com/koding/kloud/provider/openstack"

	"github.com/koding/logging"
)

const (
	VERSION = "0.0.1"
	NAME    = "kloud"
)

type Kloud struct {
	Log logging.Logger

	// Providers is responsible for creating machines and handling them.
	providers map[string]protocol.Provider

	// Storage is used to store persistent data which is used by the Provider
	// during certain actions
	Storage Storage

	// Eventers is providing an event mechanism for each method.
	Eventers map[string]eventer.Eventer

	// Deployer is executed after a successfull build
	Deployer protocol.Deployer

	// idlock provides multiple locks per id
	idlock *idlock.IdLock
}

// NewKloud creates a new Kloud instance with default providers.
func NewKloud() *Kloud {
	kld := &Kloud{
		idlock:    idlock.New(),
		Log:       logging.NewLogger(NAME),
		Eventers:  make(map[string]eventer.Eventer),
		providers: make(map[string]protocol.Provider),
	}

	kld.initializeProviders()
	return kld
}

func (k *Kloud) initializeProviders() {
	k.AddProvider("digitalocean", &digitalocean.Provider{
		Log: logging.NewLogger("digitalocean"),
	})

	k.AddProvider("amazon", &amazon.Provider{
		Log: logging.NewLogger("amazon"),
	})

	k.AddProvider("rackspace", &openstack.Provider{
		Log:          logging.NewLogger("rackspace"),
		AuthURL:      "https://identity.api.rackspacecloud.com/v2.0",
		ProviderName: "rackspace",
	})
}

// AddProvider adds the given Provider with the providerName. It returns an
// error if the provider already exists.
func (k *Kloud) AddProvider(providerName string, provider protocol.Provider) error {
	_, ok := k.providers[providerName]
	if ok {
		return NewError(ErrProviderAvailable)
	}

	k.providers[providerName] = provider
	return nil
}

// DeleteProvider removes the given provider from the provider list
func (k *Kloud) DeleteProvider(providerName string) {
	delete(k.providers, providerName)
}

// Provider returns the provider for the given provideName
func (k *Kloud) Provider(providerName string) (protocol.Provider, error) {
	provider, ok := k.providers[providerName]
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	return provider, nil
}
