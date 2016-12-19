package machinetest

import (
	"context"
	"sync"

	"koding/klient/machine"
)

// Client satisfies machine.Client interface. It mimics real client and should
// be used for testing purposes.
type Client struct {
	machine.DisconnectedClient

	mu  sync.Mutex
	ctx context.Context
}

// NewClient create a new Client instance with background context.
func NewClient() *Client {
	return &Client{
		ctx: context.Background(),
	}
}

// SetContext sets provided context to test client.
func (c *Client) SetContext(ctx context.Context) {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.ctx = ctx
}

// Context returns test client context.
func (c *Client) Context() context.Context {
	c.mu.Lock()
	defer c.mu.Unlock()

	return c.ctx
}
