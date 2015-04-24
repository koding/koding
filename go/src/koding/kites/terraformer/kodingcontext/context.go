package kodingcontext

import (
	"bytes"
	"errors"
	"io/ioutil"

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
	providers    map[string]terraform.ResourceProviderFactory
	provisioners map[string]terraform.ResourceProvisionerFactory
	Buffer       *bytes.Buffer
	ui           *cli.PrefixedUi
}

func Init(ls, rs Storage) (*Context, error) {

	config := pkg.BuiltinConfig
	if err := config.Discover(); err != nil {
		return nil, err
	}

	providers := config.ProviderFactories()
	provisioners := config.ProvisionerFactories()

	return NewContext(providers, provisioners, ls, rs), nil
}

func Close() {
	// Make sure we clean up any managed plugins at the end of this
	plugin.CleanupClients()
}

func NewContext(
	providers map[string]terraform.ResourceProviderFactory,
	provisioners map[string]terraform.ResourceProvisionerFactory,
	local Storage,
	remote Storage,
) *Context {
	b := new(bytes.Buffer)

	return &Context{
		baseDir:       "",
		providers:     providers,
		provisioners:  provisioners,
		Buffer:        b,
		RemoteStorage: remote,
		LocalStorage:  local,
		ui:            NewUI(b),
	}
}

func (c *Context) Clone() *Context {
	return NewContext(
		c.providers,
		c.provisioners,
		c.LocalStorage,
		c.RemoteStorage,
	)
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

		Providers:    c.providers,
		Provisioners: c.provisioners,
		Variables:    c.Variables,
	}
}

func (c *Context) Close() error {
	return c.LocalStorage.Clean(c.ContentID)
}
