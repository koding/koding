package kloud

import (
	"io/ioutil"
	"log"
	"os"

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

	// Providers that can satisfy procotol.Builder, protocol.Controller, etc..
	providers map[string]interface{}

	// Storage is used to store persistent data which is used by the Provider
	// during certain actions
	Storage Storage

	// Eventers is providing an event mechanism for each method.
	Eventers map[string]eventer.Eventer

	// idlock provides multiple locks per id
	idlock *idlock.IdLock

	// Enable debug mode
	Debug bool
}

// NewKloud creates a new Kloud instance with default providers.
func NewKloud() *Kloud {
	kld := &Kloud{
		idlock:    idlock.New(),
		Log:       logging.NewLogger(NAME),
		Eventers:  make(map[string]eventer.Eventer),
		providers: make(map[string]interface{}),
	}

	kld.initializeProviders()
	return kld
}

func (k *Kloud) initializeProviders() {
	// digitalocean logs trendemenous amount of log, disable it
	log.SetOutput(ioutil.Discard)

	// be sure they they satisfy the builder interface, makes it easy to catch
	// it on compile time :)
	var _ protocol.Builder = &digitalocean.Provider{}
	var _ protocol.Builder = &amazon.Provider{}
	var _ protocol.Builder = &openstack.Provider{}

	k.AddProvider("digitalocean", &digitalocean.Provider{
		Log: k.newLogger("digitalocean"),
	})

	k.AddProvider("amazon", &amazon.Provider{
		Log: k.newLogger("amazon"),
	})

	k.AddProvider("rackspace", &openstack.Provider{
		Log:          k.newLogger("rackspace"),
		AuthURL:      "https://identity.api.rackspacecloud.com/v2.0",
		ProviderName: "rackspace",
	})
}

func (k *Kloud) newLogger(name string) logging.Logger {
	log := logging.NewLogger(name)
	logHandler := logging.NewWriterHandler(os.Stderr)
	logHandler.Colorize = true
	log.SetHandler(logHandler)

	if k.Debug {
		log.SetLevel(logging.DEBUG)
		logHandler.SetLevel(logging.DEBUG)
	}

	return log
}

// AddProvider adds the given Provider with the providerName. It returns an
// error if the provider already exists.
func (k *Kloud) AddProvider(providerName string, provider interface{}) {
	k.providers[providerName] = provider
}

// Builder returns the builder for the given provideName
func (k *Kloud) Builder(providerName string) (protocol.Builder, error) {
	provider, ok := k.providers[providerName]
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	builder, ok := provider.(protocol.Builder)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	return builder, nil
}

// Controller returns the controller for the given provideName
func (k *Kloud) Controller(providerName string) (protocol.Controller, error) {
	provider, ok := k.providers[providerName]
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	controller, ok := provider.(protocol.Controller)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	return controller, nil
}

// Limiter returns the limiter for the given providername
func (k *Kloud) Limiter(providerName string) (protocol.Limiter, error) {
	provider, ok := k.providers[providerName]
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	limiter, ok := provider.(protocol.Limiter)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	return limiter, nil
}
