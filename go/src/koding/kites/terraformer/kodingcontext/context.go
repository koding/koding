// Package kodingcontext provides manages koding specific operations on top of
// terraform
package kodingcontext

import (
	"bytes"

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

// Context holds the required operational parameters for any kind of terraform
// call
type Context struct {
	Variables map[string]string

	// storage holds the plans of terraform
	RemoteStorage storage.Interface
	LocalStorage  storage.Interface

	ContentID    string
	baseDir      string
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
func (c *Context) Clone() *Context {
	cc := newContext()
	cc.Providers = c.Providers
	cc.Provisioners = c.Provisioners
	cc.LocalStorage = c.LocalStorage
	cc.RemoteStorage = c.RemoteStorage

	return cc
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
	return c.LocalStorage.Clean(c.ContentID)
}
