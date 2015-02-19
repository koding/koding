package kloud

import (
	"os"

	"koding/kites/kloud/eventer"
	"koding/kites/kloud/idlock"
	"koding/kites/kloud/protocol"

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

	// Domainer is responsible of managing dns records
	Domainer protocol.Domainer

	// Storage is used to store persistent data which is used by the Provider
	// during certain actions
	Storage Storage

	// DomainStorage is used to store persistent data about domain data
	DomainStorage protocol.DomainStorage

	// Locker is used to lock/unlock distributed locks based on unique ids
	Locker Locker

	// Eventers is providing an event mechanism for each method.
	Eventers map[string]eventer.Eventer

	// idlock provides multiple locks per id
	idlock *idlock.IdLock

	// Enable debug mode
	Debug bool
}

// New creates a new Kloud instance without initializing the default providers.
func New() *Kloud {
	kld := &Kloud{
		idlock:    idlock.New(),
		Log:       logging.NewLogger(NAME),
		Eventers:  make(map[string]eventer.Eventer),
		providers: make(map[string]interface{}),
	}

	return kld
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
