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

	// Builders is responsible for creating and provisioning machines.
	builders map[string]protocol.Builder

	// Controllers is responsible for handling machines.
	controllers map[string]protocol.Controller

	// Storage is used to store persistent data which is used by the Provider
	// during certain actions
	Storage Storage

	// Eventers is providing an event mechanism for each method.
	Eventers map[string]eventer.Eventer

	// Deployer is executed after a successfull build
	Deploy   *protocol.ProviderDeploy
	Deployer protocol.Deployer

	// idlock provides multiple locks per id
	idlock *idlock.IdLock
}

// NewKloud creates a new Kloud instance with default providers.
func NewKloud() *Kloud {
	kld := &Kloud{
		idlock:      idlock.New(),
		Log:         logging.NewLogger(NAME),
		Eventers:    make(map[string]eventer.Eventer),
		builders:    make(map[string]protocol.Builder),
		controllers: make(map[string]protocol.Controller),
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
func (k *Kloud) AddProvider(providerName string, provider interface{}) {
	builder, ok := provider.(protocol.Builder)
	if ok {
		k.builders[providerName] = builder
	}

	controller, ok := provider.(protocol.Controller)
	if ok {
		k.controllers[providerName] = controller
	}
}

// Builder returns the builder for the given provideName
func (k *Kloud) Builder(providerName string) (protocol.Builder, error) {
	builder, ok := k.builders[providerName]
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	return builder, nil
}

// Controller returns the controller for the given provideName
func (k *Kloud) Controller(providerName string) (protocol.Controller, error) {
	controller, ok := k.controllers[providerName]
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	return controller, nil
}
