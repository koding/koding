// Package kodingcontext provides manages koding specific operations on top of
// terraform
package kodingcontext

import (
	"bytes"
	"errors"

	"github.com/hashicorp/terraform/terraform"
	"github.com/mitchellh/cli"
)

func (c *context) newKodingContext(sc <-chan struct{}, contentID, traceID string) *KodingContext {
	errorBuf := new(bytes.Buffer)

	kc := &KodingContext{
		context: context{
			Providers:     c.Providers,
			Provisioners:  c.Provisioners,
			LocalStorage:  c.LocalStorage,
			RemoteStorage: c.RemoteStorage,
			log:           c.log,
		},
		ContentID:    contentID,
		Buffer:       errorBuf,
		ui:           NewUI(errorBuf, traceID),
		ShutdownChan: sc,
		debug:        c.debug,
	}

	return kc
}

// Context holds the required operational parameters for any kind of terraform
// call
type KodingContext struct {
	context

	Buffer       *bytes.Buffer
	ui           *cli.PrefixedUi
	Variables    map[string]interface{}
	ShutdownChan <-chan struct{}
	ContentID    string

	debug bool
}

// TerraformContextOpts creates a basic context options for terraform itself
func (c *KodingContext) TerraformContextOpts() *terraform.ContextOpts {
	return c.TerraformContextOptsWithPlan(nil)
}

// TerraformContextOptsWithPlan creates a new context out of a given plan
func (c *KodingContext) TerraformContextOptsWithPlan(p *terraform.Plan) *terraform.ContextOpts {
	if p == nil {
		p = &terraform.Plan{}
	}

	return &terraform.ContextOpts{
		Destroy:     false,
		Parallelism: 0,

		Hooks: nil,

		Module: p.Module,
		State:  p.State,
		Diff:   p.Diff,

		Providers:    c.Providers,
		Provisioners: c.Provisioners,
		Variables:    c.Variables,
	}
}

// Close terminates the existing context
func (c *KodingContext) Close() error {
	if c.ContentID == "" {
		return errors.New("contentID is nil")
	}

	shutdownChansMu.Lock()
	delete(shutdownChans, c.ContentID)
	shutdownChansWG.Done()
	shutdownChansMu.Unlock()

	if c.debug {
		return nil // don't remove local tf files in debug mode
	}

	return c.LocalStorage.Remove(c.ContentID)
}
