package kloud

import (
	"io/ioutil"
	"log"
	"os"

	"koding/kites/kloud/eventer"
	"koding/kites/kloud/idlock"
	"koding/kites/kloud/protocol"
	"koding/kites/kloud/provider/amazon"
	"koding/kites/kloud/provider/digitalocean"
	"koding/kites/kloud/provider/openstack"

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

	// Locker is used to lock/unlock distributed locks based on unique ids
	Locker Locker

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
	var _ protocol.Provider = &digitalocean.Provider{}
	var _ protocol.Provider = &amazon.Provider{}
	var _ protocol.Provider = &openstack.Provider{}

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
func (k *Kloud) AddProvider(providerName string, provider interface{}) error {
	_, ok := k.providers[providerName]
	if ok {
		NewError(ErrProviderAvailable)
	}

	k.providers[providerName] = provider
	return nil
}
