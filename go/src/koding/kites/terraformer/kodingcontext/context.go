// Package kodingcontext provides manages koding specific operations on top of
// terraform
package kodingcontext

import (
	"errors"
	"sync"
	"time"

	"koding/kites/terraformer/kodingcontext/pkg"
	"koding/kites/terraformer/storage"

	"github.com/hashicorp/go-plugin"
	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/logging"
)

const (
	terraformFileExt      = ".tf.json"
	terraformPlanFileExt  = ".out"
	terraformStateFileExt = ".tfstate"
	mainFileName          = "main"
	planFileName          = "plan"
	stateFileName         = "state"
)

var (
	shutdownChans   map[string]chan struct{}
	shutdownChansMu sync.Mutex
	shutdownChansWG sync.WaitGroup
)

type Context interface {
	Get(string, string) (*KodingContext, error)
	Shutdown() error
}

// Context holds the required operational parameters for any kind of terraform
// call
type context struct {
	// storage holds the plans of terraform
	RemoteStorage storage.Interface
	LocalStorage  storage.Interface

	Providers    map[string]terraform.ResourceProviderFactory
	Provisioners map[string]terraform.ResourceProvisionerFactory

	log   logging.Logger
	debug bool
}

// New creates a new context, this should not be used directly, use Clone
// instead from an existing one
func New(ls, rs storage.Interface, log logging.Logger, debug bool) (*context, error) {

	config := pkg.BuiltinConfig
	if err := config.Discover(); err != nil {
		return nil, err
	}

	c := &context{
		Providers:     config.ProviderFactories(),
		Provisioners:  config.ProvisionerFactories(),
		LocalStorage:  ls,
		RemoteStorage: rs,
		log:           log,
		debug:         debug,
	}

	shutdownChans = make(map[string]chan struct{})

	return c, nil
}

// Close closes globalbly in use variables
func Close() {
	// Make sure we clean up any managed plugins at the end of this
	plugin.CleanupClients()
}

// Get creates a new context out of an existing one, this can be called
// multiple times instead of creating a new Context with New function
func (c *context) Get(contentID, traceID string) (*KodingContext, error) {
	if contentID == "" {
		return nil, errors.New("contentID is not set")
	}

	sc, err := c.createShutdownChan(contentID)
	if err != nil {
		return nil, err
	}

	return c.newKodingContext(sc, contentID, traceID), nil
}

// BroadcastForceShutdown sends a message to the current operations
func (c *context) BroadcastForceShutdown() {
	shutdownChansMu.Lock()
	for _, shutdownChan := range shutdownChans {
		// broadcast this message to listeners
		select {
		case shutdownChan <- struct{}{}:
		default:
		}
	}
	shutdownChansMu.Unlock()
}

// Shutdown shutsdown koding context
func (c *context) Shutdown() error {
	shutdown := make(chan struct{}, 1)
	go func() {
		shutdownChansWG.Wait()
		shutdown <- struct{}{}
	}()

	after15 := time.After(time.Second * 15)
	after25 := time.After(time.Second * 25)
	after30 := time.After(time.Second * 30)
	for {
		select {
		case <-after15:
			// wait for 15 seconds, after that close forcefully, but still
			// gracefully
			c.BroadcastForceShutdown()

		case <-after25:
			// if operations dont end in 15 secs, close them ungracefully
			c.BroadcastForceShutdown()

		case <-after30:
			// return if nothing happens in 30 sec
			return errors.New("deadline reached")

		case <-shutdown:
			// if all the requests finish before 15 secs
			return nil
		}
	}
}

func (c *context) createShutdownChan(contentID string) (<-chan struct{}, error) {
	shutdownChansMu.Lock()
	defer shutdownChansMu.Unlock()

	_, ok := shutdownChans[contentID]
	if ok {
		return nil, errors.New("content is already locked")
	}

	resultCh := make(chan struct{})

	shutdownChans[contentID] = resultCh
	shutdownChansWG.Add(1)
	return resultCh, nil
}
