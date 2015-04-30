// Package kodingcontext provides manages koding specific operations on top of
// terraform
package kodingcontext

import (
	"bytes"
	"errors"
	"os"
	"os/signal"
	"sync"
	"syscall"

	"koding/kites/terraformer/kodingcontext/pkg"
	"koding/kites/terraformer/storage"

	"github.com/hashicorp/terraform/plugin"
	"github.com/hashicorp/terraform/terraform"
	"github.com/mitchellh/cli"
)

var (
	shutdownChans   map[string]chan struct{}
	shutdownChansMu sync.Mutex
	shutdownChansWG sync.WaitGroup
)

const (
	terraformFileExt      = ".tf"
	terraformPlanFileExt  = ".out"
	terraformStateFileExt = ".tfstate"
	mainFileName          = "main"
	planFileName          = "plan"
	stateFileName         = "state"
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
	baseDir      string
	Providers    map[string]terraform.ResourceProviderFactory
	Provisioners map[string]terraform.ResourceProvisionerFactory
	Buffer       *bytes.Buffer
	ui           *cli.PrefixedUi
	closeChan    chan struct{}
}

// New creates a new Context, this should not be used directly, use Clone
// instead from an existing one
func New(ls, rs storage.Interface, closeChan chan struct{}) (*Context, error) {

	config := pkg.BuiltinConfig
	if err := config.Discover(); err != nil {
		return nil, err
	}

	c := newContext()
	c.Providers = config.ProviderFactories()
	c.Provisioners = config.ProvisionerFactories()
	c.LocalStorage = ls
	c.RemoteStorage = rs
	c.closeChan = closeChan

	// create global shut down handlers
	c.makeShutdownChans()

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
		baseDir: "",
		Buffer:  b,
		ui:      NewUI(b),
	}
}

// Clone creates a new context out of an existing one, this can be called
// multiple times instead of creating a new Context with New function
func (c *Context) Get(contentID string) (*Context, error) {
	if contentID == "" {
		return nil, errors.New("contentID is not set")
	}

	sc, err := createShutdownChan(contentID)
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
	if c.ContentID != "" {
		shutdownChansMu.Lock()
		delete(shutdownChans, c.ContentID)
		shutdownChansWG.Done()
		shutdownChansMu.Unlock()
	}

	return c.LocalStorage.Remove(c.ContentID)
}

func createShutdownChan(contentID string) (<-chan struct{}, error) {
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

func (c *Context) makeShutdownChans() {
	// init channels map
	shutdownChans = make(map[string]chan struct{})
	go func() {
		signalCh := make(chan os.Signal, 1)
		signal.Notify(signalCh)

		s := <-signalCh
		signal.Stop(signalCh)
		switch s {
		case syscall.SIGINT, syscall.SIGTERM, syscall.SIGKILL:
			shutdownChansMu.Lock()
			// broadcast this message to others
			for _, shutdownChan := range shutdownChans {
				shutdownChan <- struct{}{}
			}
			shutdownChansMu.Unlock()
		}

		shutdownChansWG.Wait()
		close(c.closeChan)
	}()
}
