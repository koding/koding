package machine

import (
	"context"
	"errors"

	"koding/klient/machine/mount/index"
)

var (
	// ErrDisconnected indicates that provided machine is unreachable by any of
	// its clients.
	ErrDisconnected = errors.New("machine disconnected")
)

var _ ClientBuilder = (*DisconnectedClientBuilder)(nil)

// DisconnectedClientBuilder satisfies ClientBuilder. It produces disconnected
// clients. And will never return any errors.
type DisconnectedClientBuilder struct{}

// Ping is a stub for pinging method since we can't ping the machine when we
// are disconnected by design.
func (DisconnectedClientBuilder) Ping(_ DynamicAddrFunc) (Status, Addr, error) {
	return Status{}, Addr{}, nil
}

// Build always returns disconnected client.
func (DisconnectedClientBuilder) Build(ctx context.Context, _ Addr) Client {
	return NewDisconnectedClient(ctx)
}

var _ Client = (*DisconnectedClient)(nil)

// DisconnectedClient satisfies Client interface. It indicates disconnected
// machine and always returns
type DisconnectedClient struct {
	ctx context.Context
}

// NewDisconnectedClient creates a new disconnected client with given context.
func NewDisconnectedClient(ctx context.Context) *DisconnectedClient {
	return &DisconnectedClient{
		ctx: ctx,
	}
}

// CurrentUser always returns ErrDisconnected error.
func (*DisconnectedClient) CurrentUser() (string, error) {
	return "", ErrDisconnected
}

// SSHAddKeys always returns ErrDisconnected error.
func (*DisconnectedClient) SSHAddKeys(_ string, _ ...string) error {
	return ErrDisconnected
}

// MountHeadIndex always returns ErrDisconnected error.
func (*DisconnectedClient) MountHeadIndex(_ string) (string, int, int64, error) {
	return "", 0, 0, ErrDisconnected
}

// MountGetIndex always returns ErrDisconnected error.
func (*DisconnectedClient) MountGetIndex(_ string) (*index.Index, error) {
	return nil, ErrDisconnected
}

// Context returns disconnected client's context.
func (d *DisconnectedClient) Context() context.Context {
	return d.ctx
}
