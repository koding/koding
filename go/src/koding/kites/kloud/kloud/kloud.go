package kloud

import (
	"os"

	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/pkg/idlock"
	"koding/kites/kloud/terraformer"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/koding/metrics"
	"golang.org/x/net/context"
)

const (
	VERSION = "0.0.1"
	NAME    = "kloud"
)

type Kloud struct {
	Log logging.Logger

	// rename to providers once finished
	// Providers that can satisfy procotol.Builder, protocol.Controller, etc..
	providers map[string]interface{}

	// Domainer is responsible of managing dns records
	Domainer dnsclient.Client

	// DomainStorage is used to store persistent data about domain data
	DomainStorage dnsstorage.Storage

	// Locker is used to lock/unlock distributed locks based on unique ids
	Locker Locker

	// Eventers is providing an event mechanism for each method.
	Eventers map[string]eventer.Eventer

	// idlock provides multiple locks per id
	idlock *idlock.IdLock

	// ContextCreator is used to pass a manual context to each request. If not
	// set context.Background()) is passed.
	ContextCreator func(context.Context) context.Context

	// If available a key pair with the given public key and name should be
	// deployed to the machine, the corresponding PrivateKey should be returned
	// in the ProviderArtifact. Some providers such as Amazon creates
	// publicKey's on the fly and generates the privateKey themself.
	PublicKeys *publickeys.Keys

	Metrics *metrics.DogStatsD

	terraformerKite *terraformer.Terraformer

	// Enable debug mode
	Debug bool
}

// New creates a new Kloud instance without initializing the default providers.
func New(k *kite.Kite) *Kloud {
	kld := &Kloud{
		idlock:    idlock.New(),
		Log:       logging.NewLogger(NAME),
		Eventers:  make(map[string]eventer.Eventer),
		providers: make(map[string]interface{}, 0),
	}

	// this creates a reconnectable kite connection to a local terraformer
	// instance. We don't check error, instead of panicing or returning just
	// fail, so any other functionality still works. TerraformerKite will be
	// nil and any handler that will have access to it need to check it first
	tfKite, _ := terraformer.Connect(k)
	kld.terraformerKite = tfKite
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
