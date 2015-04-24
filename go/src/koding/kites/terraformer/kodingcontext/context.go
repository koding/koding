package kodingcontext

import (
	"bytes"
	"errors"

	"koding/kites/terraformer/kodingcontext/pkg"

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
	ErrBaseDirNotSet   = errors.New("baseDir is not set")
	ErrVariablesNotSet = errors.New("Variables is not set")
)

type Context struct {
	Variables map[string]string

	// storage holds the plans of terraform
	RemoteStorage Storage
	LocalStorage  Storage

	ContentID    string
	baseDir      string
	Providers    map[string]terraform.ResourceProviderFactory
	Provisioners map[string]terraform.ResourceProvisionerFactory
	Buffer       *bytes.Buffer
	ui           *cli.PrefixedUi
}

func New(ls, rs Storage) (*Context, error) {

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

func (c *Context) Clone() *Context {
	cc := newContext()
	cc.Providers = c.Providers
	cc.Provisioners = c.Provisioners
	cc.LocalStorage = c.LocalStorage
	cc.RemoteStorage = c.RemoteStorage

	return cc
}

func (c *Context) TerraformContextOpts() *terraform.ContextOpts {
	return c.TerraformContextOptsWithPlan(nil)
}

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

func (c *Context) Close() error {
	return c.LocalStorage.Clean(c.ContentID)
}
