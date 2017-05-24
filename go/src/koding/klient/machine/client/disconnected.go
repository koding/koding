package client

import (
	"context"
	"errors"

	"koding/klient/machine"
	"koding/klient/machine/index"
	"koding/klient/os"
)

var (
	// ErrDisconnected indicates that provided machine is unreachable by any of
	// its clients.
	ErrDisconnected = errors.New("machine disconnected")
)

var _ Builder = (*DisconnectedBuilder)(nil)

// DisconnectedBuilder satisfies ClientBuilder. It produces disconnected
// clients. And will never return any errors.
type DisconnectedBuilder struct{}

// Ping is a stub for pinging method since we can't ping the machine when we
// are disconnected by design.
func (DisconnectedBuilder) Ping(_ DynamicAddrFunc) (machine.Status, machine.Addr, error) {
	return machine.Status{}, machine.Addr{}, nil
}

// Build always returns disconnected client.
func (DisconnectedBuilder) Build(ctx context.Context, _ machine.Addr) Client {
	return NewDisconnected(ctx)
}

// IP always returns ErrDisconnected error.
func (DisconnectedBuilder) IP(_ machine.Addr) (machine.Addr, error) {
	return machine.Addr{}, ErrDisconnected
}

var _ Client = (*Disconnected)(nil)

// Disconnected satisfies Client interface. It indicates disconnected machine
// and always returns.
type Disconnected struct {
	ctx context.Context
}

// NewDisconnected creates a new disconnected client with given context.
func NewDisconnected(ctx context.Context) *Disconnected {
	return &Disconnected{
		ctx: ctx,
	}
}

// CurrentUser always returns ErrDisconnected error.
func (*Disconnected) CurrentUser() (string, error) {
	return "", ErrDisconnected
}

// Abs always returns ErrDisconnected error.
func (*Disconnected) Abs(_ string) (string, bool, bool, error) {
	return "", false, false, ErrDisconnected
}

// SSHAddKeys always returns ErrDisconnected error.
func (*Disconnected) SSHAddKeys(_ string, _ ...string) error {
	return ErrDisconnected
}

// MountHeadIndex always returns ErrDisconnected error.
func (*Disconnected) MountHeadIndex(_ string) (string, int, int64, error) {
	return "", 0, 0, ErrDisconnected
}

// MountGetIndex always returns ErrDisconnected error.
func (*Disconnected) MountGetIndex(_ string) (*index.Index, error) {
	return nil, ErrDisconnected
}

// Exec always returns ErrDisconnected error.
func (*Disconnected) Exec(*os.ExecRequest) (*os.ExecResponse, error) {
	return nil, ErrDisconnected
}

// Kill always returns ErrDisconnected error.
func (*Disconnected) Kill(*os.KillRequest) (*os.KillResponse, error) {
	return nil, ErrDisconnected
}

// Context returns disconnected client's context.
func (d *Disconnected) Context() context.Context {
	return d.ctx
}
