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

// IsDisconnected is a helper function that checks if provided error describes
// unreachable machine.
func IsDisconnected(err error) bool {
	return err == ErrDisconnected
}

var _ Client = (*DisconnectedClient)(nil)

// DisconnectedClient satisfies Client interface. It indicates disconnected
// machine and always returns
type DisconnectedClient struct{}

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
