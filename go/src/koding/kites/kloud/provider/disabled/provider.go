package disabled

import (
	"fmt"
	"strconv"

	"koding/kites/kloud/stack"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

// Provider is a fake provider used as replacement for misconfigured
// kloud provider. E.g. if koding provider has no AWS credentials
// configured it's replaced with disabled provider.
type Provider struct {
	err *kite.Error
}

// NewProvider gives new disabled kloud provider value which rejects each
// request with 411 kite error.
func NewProvider(name string) *Provider {
	return &Provider{
		err: &kite.Error{
			Type:    "kloudError",
			Message: fmt.Sprintf("Provider %q is disabled (error code: %d)", name, stack.ErrProviderIsDisabled),
			CodeVal: strconv.Itoa(stack.ErrProviderIsDisabled),
		},
	}
}

// ensure *Provider implements the kloud.Interface interface
var _ stack.Interface = (*Provider)(nil)

// Machine implements the kloud.Provider interface.
func (p *Provider) Machine(context.Context, string) (interface{}, error) {
	return nil, p.err
}

// Build implements the kloud.Builder interface.
func (p *Provider) Build(context.Context) error {
	return p.err
}

// Destroy implements the kloud.Destroyer interface.
func (p *Provider) Destroy(context.Context) error {
	return p.err
}

// Info implements the kloud.Infoer interface.
func (p *Provider) Info(context.Context) (map[string]string, error) {
	return nil, p.err
}

// Stop implements the kloud.Stoper interface.
func (p *Provider) Stop(context.Context) error {
	return p.err
}

// Start implements the kloud.Starter interface.
func (p *Provider) Start(context.Context) error {
	return p.err
}

// Reinit implements the kloud.Reiniter interface.
func (p *Provider) Reinit(context.Context) error {
	return p.err
}

// Resize implements the kloud.Resizeer interface.
func (p *Provider) Resize(context.Context) error {
	return p.err
}

// Restart implements the kloud.Restarter interface.
func (p *Provider) Restart(context.Context) error {
	return p.err
}

// CreateSnapshot implements the kloud.CreateSnapshoter interface.
func (p *Provider) CreateSnapshot(context.Context) error {
	return p.err
}

// DeleteSnapshot implements the kloud.DeleteSnapshoter interface.
func (p *Provider) DeleteSnapshot(context.Context) error {
	return p.err
}
