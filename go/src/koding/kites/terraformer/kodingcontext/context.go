package kodingcontext

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"path"

	"koding/kites/terraformer/kodingcontext/pkg"

	"github.com/hashicorp/terraform/plugin"
	"github.com/hashicorp/terraform/terraform"
	"github.com/mitchellh/cli"
	uuid "github.com/nu7hatch/gouuid"
)

const (
	terraformFileExt = ".tf"
	mainFileName     = "main"
	planFileName     = "plan"
)

var (
	ErrBaseDirNotSet   = errors.New("baseDir is not set")
	ErrVariablesNotSet = errors.New("Variables is not set")
)

type Context struct {
	Variables map[string]string

	// storage holds the plans of terraform
	Storage Storage

	baseDir      string
	providers    map[string]terraform.ResourceProviderFactory
	provisioners map[string]terraform.ResourceProvisionerFactory
	id           string
	Buffer       *bytes.Buffer
	ui           *cli.PrefixedUi
}

func Init() (*Context, error) {

	config := pkg.BuiltinConfig
	if err := config.Discover(); err != nil {
		return nil, err
	}

	providers := config.ProviderFactories()
	provisioners := config.ProvisionerFactories()

	return NewContext(providers, provisioners), nil
}

func Close() {
	// Make sure we clean up any managed plugins at the end of this
	plugin.CleanupClients()
}

func NewContext(
	providers map[string]terraform.ResourceProviderFactory,
	provisioners map[string]terraform.ResourceProvisionerFactory,
) *Context {
	id, err := uuid.NewV4()
	if err != nil {
		panic(fmt.Sprintf("kite: cannot generate unique ID: %s", err.Error()))
	}

	b := new(bytes.Buffer)

	return &Context{
		baseDir:      "",
		providers:    providers,
		provisioners: provisioners,
		id:           id.String(),
		Buffer:       b,
		ui:           NewUI(b),
		Storage:      FileStorage{},
	}
}

func (c *Context) Clone() *Context {
	return NewContext(c.providers, c.provisioners)
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
	dir, err := c.Storage.BasePath()
	if err != nil {
		return err
	}

	return c.Storage.Clean(dir)
}

func (c *Context) createDirAndFile(content io.Reader) (dir string, err error) {
	dir, err = c.Storage.BasePath()
	if err != nil {
		return "", err
	}

	path := path.Join(dir, c.id+mainFileName+terraformFileExt)

	if err := c.Storage.Write(path, content); err != nil {
		return "", err
	}

	return dir, nil
}

// getBaseDir creates a new temp directory or returns the existing exclusive one
// for the current context
func (c *Context) getBaseDir() (string, error) {
	if c.baseDir != "" {
		return c.baseDir, nil
	}

	// create dir
	// calling TempDir simultaneously will not choose the same directory.
	dir, err := ioutil.TempDir("", "terraformer")
	if err != nil {
		return "", err
	}

	c.baseDir = dir

	return c.baseDir, nil
}
