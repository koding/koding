package kloud

import (
	"io/ioutil"
	"log"
	"os"

	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/idlock"
	"github.com/koding/kloud/protocol"
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

	Storage   Storage
	Eventers  map[string]eventer.Eventer
	Providers map[string]protocol.Provider
	Deployer  protocol.Deployer

	idlock *idlock.IdLock

	Name    string
	Version string

	Debug bool
}

// NewKloud creates a new Kloud instance with default providers.
func NewKloud() *Kloud {
	kld := &Kloud{
		Name:     NAME,
		Version:  VERSION,
		idlock:   idlock.New(),
		Log:      logging.NewLogger(NAME),
		Eventers: make(map[string]eventer.Eventer),
	}

	kld.initializeProviders()

	return kld
}

func (k *Kloud) initializeProviders() {
	// Our digitalocean api uses lots of logs, the only way to supress them is
	// to disable std log package.
	log.SetOutput(ioutil.Discard)

	k.Providers = map[string]protocol.Provider{
		"digitalocean": &digitalocean.Provider{
			Log: Logger("digitalocean", k.Debug),
		},
		"rackspace": &openstack.Provider{
			Log:          Logger("rackspace", k.Debug),
			AuthURL:      "https://identity.api.rackspacecloud.com/v2.0",
			ProviderName: "rackspace",
		},
	}
}

func (k *Kloud) GetProvider(providerName string) (protocol.Provider, error) {
	provider, ok := k.Providers[providerName]
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	return provider, nil
}

func Logger(name string, debug bool) logging.Logger {
	log := logging.NewLogger(name)
	writerHandler := logging.NewWriterHandler(os.Stderr)
	writerHandler.Colorize = true

	if debug {
		log.SetLevel(logging.DEBUG)
		writerHandler.SetLevel(logging.DEBUG)
	}

	log.SetHandler(writerHandler)
	return log
}
