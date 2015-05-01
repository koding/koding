// Package kodingcontext provides manages koding specific operations on top of
// terraform
package kodingcontext

import (
	"bytes"
	"errors"
	"sync"
	"time"

	"koding/kites/terraformer/kodingcontext/pkg"
	"koding/kites/terraformer/storage"

	"github.com/hashicorp/terraform/plugin"
	"github.com/hashicorp/terraform/terraform"
	"github.com/mitchellh/cli"
)

const (
	terraformFileExt      = ".tf"
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

// Context holds the required operational parameters for any kind of terraform
// call
type Context struct {
	Variables map[string]string

	// storage holds the plans of terraform
	RemoteStorage storage.Interface
	LocalStorage  storage.Interface

	ShutdownChan <-chan struct{}

	ContentID    string
	Providers    map[string]terraform.ResourceProviderFactory
	Provisioners map[string]terraform.ResourceProvisionerFactory
	Buffer       *bytes.Buffer
	ui           *cli.PrefixedUi
}

// New creates a new Context, this should not be used directly, use Clone
// instead from an existing one
func New(ls, rs storage.Interface) (*Context, error) {

	config := pkg.BuiltinConfig
	if err := config.Discover(); err != nil {
		return nil, err
	}

	c := newContext()
	c.Providers = config.ProviderFactories()
	c.Provisioners = config.ProvisionerFactories()
	c.LocalStorage = ls
	c.RemoteStorage = rs

	shutdownChans = make(map[string]chan struct{})

	return c, nil
}

// Close closes globalbly in use variables
func Close() {
	// Make sure we clean up any managed plugins at the end of this
	plugin.CleanupClients()
}

func newContext() *Context {
	b := new(bytes.Buffer)

	return &Context{
		Buffer: b,
		ui:     NewUI(b),
	}
}

// Get creates a new context out of an existing one, this can be called
// multiple times instead of creating a new Context with New function
func (c *Context) Get(contentID string) (*Context, error) {
	if contentID == "" {
		return nil, errors.New("contentID is not set")
	}

	sc, err := c.createShutdownChan(contentID)
	if err != nil {
		return nil, err
	}

	cc := newContext()
	cc.ContentID = contentID
	cc.Providers = c.Providers
	cc.Provisioners = c.Provisioners
	cc.LocalStorage = c.LocalStorage
	cc.RemoteStorage = c.RemoteStorage
	cc.ShutdownChan = sc

	return cc, nil
}

// TerraformContextOpts creates a basic context options for terraform itself
func (c *Context) TerraformContextOpts() *terraform.ContextOpts {
	return c.TerraformContextOptsWithPlan(nil)
}

// TerraformContextOptsWithPlan creates a new context out of a given plan
func (c *Context) TerraformContextOptsWithPlan(p *terraform.Plan) *terraform.ContextOpts {
	if p == nil {
		p = &terraform.Plan{}
	}

	return &terraform.ContextOpts{
		Destroy:     false, // this should be true with kite.destroy command
		Parallelism: 0,

		Hooks: nil,

		// Targets      []string
		Module: p.Module,
		State:  p.State,
		Diff:   p.Diff,

		Providers:    c.Providers,
		Provisioners: c.Provisioners,
		Variables:    c.Variables,
	}
}

// Close terminates the existing context
func (c *Context) Close() error {
	// content id is null for parent context
	if c.ContentID != "" {
		shutdownChansMu.Lock()
		delete(shutdownChans, c.ContentID)
		shutdownChansWG.Done()
		shutdownChansMu.Unlock()
	}

	return c.LocalStorage.Remove(c.ContentID)
}

// BroadcastForceShutdown sends a message to the current operations
func (c *Context) BroadcastForceShutdown() {
	shutdownChansMu.Lock()
	for _, shutdownChan := range shutdownChans {
		// broadcast this message to listeners
		shutdownChan <- struct{}{}
	}
	shutdownChansMu.Unlock()
}

// Shutdown shutsdown koding context
func (c *Context) Shutdown() error {
	shutdown := make(chan struct{})
	go func() {
		shutdownChansWG.Wait()
		close(shutdown)
	}()

	select {
	case <-time.After(time.Second * 15):
		// wait for 15 seconds, after that close forcefully, but still
		// gracefully
		c.BroadcastForceShutdown()

	case <-time.After(time.Second * 25):
		// if operations dont end in 15 secs, close them ungracefully
		c.BroadcastForceShutdown()

	case <-time.After(time.Second * 30):
		// return if nothing happens in 30 sec
		return errors.New("deadline reached")

	case <-shutdown:
		// if all the requests finish before 15 secs
		return nil
	}

	return nil
}

func (c *Context) createShutdownChan(contentID string) (<-chan struct{}, error) {
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
