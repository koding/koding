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

// ensure *Provider implements the stack.Interface interface
var _ stack.Interface = (*Provider)(nil)

// Machine implements the stack.Provider interface.
func (p *Provider) Machine(context.Context, string) (stack.Machine, error) {
	return nil, p.err
}

// Stack implements the stack.Provider interface.
func (p *Provider) Stack(context.Context) (stack.Stack, error) {
	return nil, p.err
}

// Cred implements the stack.Provider interface.
func (p *Provider) Cred() interface{} {
	return nil
}

// Build implements the stack.Builder interface.
func (p *Provider) Build(context.Context) error {
	return p.err
}

// Destroy implements the stack.Destroyer interface.
func (p *Provider) Destroy(context.Context) error {
	return p.err
}

// Info implements the stack.Infoer interface.
func (p *Provider) Info(context.Context) (*stack.InfoResponse, error) {
	return nil, p.err
}

// Stop implements the stack.Stoper interface.
func (p *Provider) Stop(context.Context) error {
	return p.err
}

// Start implements the stack.Starter interface.
func (p *Provider) Start(context.Context) error {
	return p.err
}

// Reinit implements the stack.Reiniter interface.
func (p *Provider) Reinit(context.Context) error {
	return p.err
}

// Resize implements the stack.Resizeer interface.
func (p *Provider) Resize(context.Context) error {
	return p.err
}

// Restart implements the stack.Restarter interface.
func (p *Provider) Restart(context.Context) error {
	return p.err
}

// CreateSnapshot implements the stack.CreateSnapshoter interface.
func (p *Provider) CreateSnapshot(context.Context) error {
	return p.err
}

// DeleteSnapshot implements the stack.DeleteSnapshoter interface.
func (p *Provider) DeleteSnapshot(context.Context) error {
	return p.err
}
