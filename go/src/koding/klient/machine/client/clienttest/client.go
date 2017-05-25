package clienttest

import (
	"context"
	"errors"
	"fmt"
	"os/user"
	"path/filepath"
	"sync"
	"sync/atomic"
	"time"

	"koding/klient/fs"
	"koding/klient/machine"
	"koding/klient/machine/client"
	"koding/klient/machine/index"
	"koding/klient/os"
)

// Builder uses Server logic to build test clients.
type Builder struct {
	c       *Client
	buildsN int64
	ch      chan struct{}
}

// NewBuilder creates a new Builder object that uses provided test client. If
// test client is nil, the default one will be created.
func NewBuilder(c *Client) *Builder {
	if c == nil {
		c = NewClient()
	}

	return &Builder{
		c:  c,
		ch: make(chan struct{}),
	}
}

// Ping returns machine statuses based on Server response.
func (*Builder) Ping(dynAddr client.DynamicAddrFunc) (machine.Status, machine.Addr, error) {
	if dynAddr == nil {
		panic("nil dynamic function generator")
	}

	states := map[string]machine.State{
		"":    machine.StateUnknown,
		"on":  machine.StateOnline,
		"off": machine.StateOffline,
	}
	for network, state := range states {
		if addr, err := dynAddr(network); err == nil {
			return machine.Status{State: state}, addr, err
		}
	}

	return machine.Status{}, machine.Addr{}, machine.ErrAddrNotFound
}

// Build creates a nil client and increases builds counter.
func (n *Builder) Build(ctx context.Context, _ machine.Addr) client.Client {
	go func() {
		atomic.AddInt64(&n.buildsN, 1)
		n.ch <- struct{}{}
	}()

	n.c.SetContext(ctx)
	return n.c
}

// IP always returns local host IP address.
func (n *Builder) IP(_ machine.Addr) (machine.Addr, error) {
	return machine.Addr{}, errors.New("not implemented")
}

// WaitForBuild waits for invocation of Build method. It times out after
// specified duration.
func (n *Builder) WaitForBuild(timeout time.Duration) error {
	select {
	case <-n.ch:
		return nil
	case <-time.After(timeout):
		return fmt.Errorf("timed out after %s", timeout)
	}
}

// BuildsCount returns how many times Build method was invoked.
func (n *Builder) BuildsCount() int {
	return int(atomic.LoadInt64(&n.buildsN))
}

// Client satisfies machine.Client interface. It mimics real client and should
// be used for testing purposes.
type Client struct {
	mu  sync.Mutex
	ctx context.Context
}

var _ client.Client = (*Client)(nil)

// NewClient create a new Client instance with background context.
func NewClient() *Client {
	return &Client{
		ctx: context.Background(),
	}
}

// CurrentUser returns the current user of local machine.
func (c *Client) CurrentUser() (string, error) {
	u, err := user.Current()
	if err != nil {
		return "", err
	}

	return u.Username, nil
}

// Abs returns absolute representation of given path.
func (c *Client) Abs(path string) (string, bool, bool, error) {
	return fs.DefaultFS.Abs(path)
}

// SSHAddKeys is a no-op method and always returns nil.
func (c *Client) SSHAddKeys(_ string, _ ...string) error {
	return nil
}

// MountHeadIndex gets basic info about the index generated from local path.
func (c *Client) MountHeadIndex(path string) (string, int, int64, error) {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return "", 0, 0, err
	}

	idx, err := c.MountGetIndex(absPath)
	if err != nil {
		return "", 0, 0, err
	}

	return absPath, idx.Tree().Count(), idx.Tree().DiskSize(), nil
}

// MountGetIndex creates an index from provided local path. Generated index is
// not cached.
func (c *Client) MountGetIndex(path string) (*index.Index, error) {
	return index.NewIndexFiles(path, nil)
}

// Exec mocks running process on a remote, always succeeds.
func (c *Client) Exec(*os.ExecRequest) (*os.ExecResponse, error) {
	return &os.ExecResponse{PID: 0xD}, nil
}

// Kill mocks remote process termination, always succeeds.
func (c *Client) Kill(*os.KillRequest) (*os.KillResponse, error) {
	return &os.KillResponse{}, nil
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
