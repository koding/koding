package stack

import (
	"errors"
	"sync"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/keygen"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/pkg/idlock"

	"github.com/koding/cache"
	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/satori/go.uuid"
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

	// statusCache is used to cache stack statuses for describeStack calls.
	statusCache *cache.MemoryTTL

	// Domainer is responsible of managing dns records
	Domainer dnsclient.Client

	// DomainStorage is used to store persistent data about domain data
	DomainStorage dnsstorage.Storage

	// Locker is used to lock/unlock distributed locks based on unique ids
	Locker Locker

	// Eventers is providing an event mechanism for each method.
	Eventers map[string]eventer.Eventer

	// mu protects Eventers
	mu sync.RWMutex

	// idlock provides multiple locks per id
	idlock *idlock.IdLock

	// SecretKey is used for authentication with kloudctl tool.
	SecretKey string

	// ContextCreator is used to pass a manual context to each request. If not
	// set context.Background()) is passed.
	ContextCreator func(context.Context) context.Context

	// If available a key pair with the given public key and name should be
	// deployed to the machine, the corresponding PrivateKey should be returned
	// in the ProviderArtifact. Some providers such as Amazon creates
	// publicKey's on the fly and generates the privateKey themself.
	PublicKeys *publickeys.Keys

	Metrics *metrics.DogStatsD

	// Enable debug mode
	Debug bool
}

// New creates a new Kloud instance without initializing the default providers.
func New() *Kloud {
	kld := &Kloud{
		idlock:      idlock.New(),
		Log:         logging.NewLogger(NAME),
		Eventers:    make(map[string]eventer.Eventer),
		providers:   make(map[string]interface{}, 0),
		statusCache: cache.NewMemoryWithTTL(time.Second * 10),
	}

	kld.statusCache.StartGC(time.Second * 5)

	return kld
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

func (k *Kloud) setTraceID(user, method string, ctx context.Context) context.Context {
	traceID := uuid.NewV4().String()
	k.Log.Info("Tracing request for user=%s, method=%s: %s", user, method, traceID)
	return context.WithValue(ctx, TraceKey, traceID)
}

// ValidateUser is an AuthFunc, that ensures user is active.
func (k *Kloud) ValidateUser(req *keygen.AuthRequest) error {
	status, err := modelhelper.UserStatus(req.User)
	if err != nil {
		return err
	}

	switch status {
	case models.UserActive, models.UserConfirmed:
		return nil
	default:
		return errors.New("user is not active")
	}
}
