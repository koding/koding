package stack

import (
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"sync"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/config"
	"koding/kites/keygen"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/credential"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machine"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/pkg/idlock"
	"koding/kites/kloud/team"
	"koding/kites/kloud/userdata"
	"koding/remoteapi"

	dogstatsd "github.com/DataDog/datadog-go/statsd"
	"github.com/koding/cache"
	"github.com/koding/kite"
	"github.com/koding/logging"
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
	providers map[string]Provider

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

	// Endpoints represents Koding endpoints configuration.
	Endpoints *config.Endpoints

	// Userdata is used to generate new kite.keys.
	Userdata *userdata.Userdata

	// DescribeFunc is used to obtain provider types description.
	//
	// TODO(rjeczalik): It wraps provider.Desc function to avoid circular
	// dependency. The Kloud kite handlers should be moved from this
	// package to kloud one in order to solve this and improve the
	// import structure.
	DescribeFunc func(providers ...string) map[string]*Description

	// NewStack is used to create new Stacker value out of the given
	// kite and team requests.
	//
	// If nil, default implementation is used.
	NewStack func(*kite.Request, *TeamRequest) (Stacker, context.Context, error)

	// CredClient handles credential.* methods.
	CredClient *credential.Client

	// MachineClient handles machine.* methods.
	MachineClient *machine.Client

	// TeamClient handles team.* methods.
	TeamClient *team.Client

	// RemoteClient handles requests to "remote.api" endpoint.
	RemoteClient *remoteapi.Client

	Metrics *dogstatsd.Client

	// Enable debug mode
	Debug bool

	// Environment is a kite environment that kloud runs in.
	Environment string
}

// New creates a new Kloud instance without initializing the default providers.
func New() *Kloud {
	log := logging.NewLogger(NAME)

	kld := &Kloud{
		idlock:      idlock.New(),
		Log:         log,
		Eventers:    make(map[string]eventer.Eventer),
		providers:   make(map[string]Provider),
		statusCache: cache.NewMemoryWithTTL(time.Second * 10),
	}

	kld.statusCache.StartGC(time.Second * 5)

	return kld
}

// AddProvider adds the given Provider with the providerName. It returns an
// error if the provider already exists.
func (k *Kloud) AddProvider(providerName string, provider Provider) error {
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

// ReadProviders reads all providers used in the given stack template.
func ReadProviders(template []byte) ([]string, error) {
	var v struct {
		Provider map[string]struct{} `json:"provider"`
	}

	if err := json.Unmarshal(template, &v); err != nil {
		return nil, err
	}

	providers := make([]string, 0, len(v.Provider))

	for p := range v.Provider {
		providers = append(providers, p)
	}

	sort.Strings(providers)

	return providers, nil
}

// ReadProvider reads exact one cloud provider from the given template.
//
// The function returns non-nil error if none or more than one provider
// is read.
func ReadProvider(template []byte) (string, error) {
	providers, err := ReadProviders(template)
	if err != nil {
		return "", err
	}

	switch len(providers) {
	case 0:
		return "", errors.New("no provider found")
	case 1:
		return providers[0], nil
	default:
		return "", fmt.Errorf("multiple providers found: %v", providers)
	}
}
