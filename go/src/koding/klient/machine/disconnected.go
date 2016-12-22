package machine

import (
	"context"
	"errors"
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
func (DisconnectedClientBuilder) Build(_ context.Context, _ Addr) Client {
	return DisconnectedClient{}
}

var _ Client = (*DisconnectedClient)(nil)

// DisconnectedClient satisfies Client interface. It indicates disconnected
// machine and always returns
type DisconnectedClient struct{}

// CurrentUser always returns ErrDisconnected error.
func (DisconnectedClient) CurrentUser() (string, error) {
	return "", ErrDisconnected
}

// SSHAddKeys always returns ErrDisconnected error.
func (DisconnectedClient) SSHAddKeys(_ string, _ ...string) error {
	return ErrDisconnected
}
