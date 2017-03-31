package client

import (
	"context"
	"time"

	"koding/klient/machine/index"
	"koding/klient/os"
)

// DynamicClientFunc is an adapter that allows to dynamically provide clients.
type DynamicClientFunc func() (Client, error)

// Supervised is a decorator type for Clients which will wait for valid client
// if the current client is Disconnected. This type is meant to handle temporary
// network issues or cases when underlying client is not set up yet. Eg. when
// program started but haven't made connection to remote machine yet.
type Supervised struct {
	dcf     DynamicClientFunc
	timeout time.Duration
}

var _ Client = (*Supervised)(nil)

// NewSupervised creates a new Supervised client instance.
func NewSupervised(dcf DynamicClientFunc, timeout time.Duration) *Supervised {
	return &Supervised{
		timeout: timeout,
		dcf:     dcf,
	}
}

// CurrentUser calls registered Client's CurrentUser method and returns its
// result if it's not produced by Disconnected client. If it is, this function
// will wait until valid client is available or timeout is reached.
func (s *Supervised) CurrentUser() (user string, err error) {
	fn := func(c Client) error {
		user, err = c.CurrentUser()
		return err
	}

	err = s.call(fn)
	return
}

// Abs calls registered Client's Abs method and returns its result if it's not
// produced by Disconnected client. If it is, this function will wait until
// valid client is available or timeout is reached.
func (s *Supervised) Abs(path string) (absPath string, isDir, exist bool, err error) {
	fn := func(c Client) error {
		absPath, isDir, exist, err = c.Abs(path)
		return err
	}

	err = s.call(fn)
	return
}

// SSHAddKeys calls registered Client's SSHAddKeys method and returns its result
// if it's not produced by Disconnected client. If it is, this function will
// wait until valid client is available or timeout is reached.
func (s *Supervised) SSHAddKeys(username string, keys ...string) (err error) {
	fn := func(c Client) error {
		return c.SSHAddKeys(username, keys...)
	}

	return s.call(fn)
}

// MountHeadIndex calls registered Client's MountHeadIndex method and returns
// its result if it's not produced by Disconnected client. If it is, this
// function will wait until valid client is available or timeout is reached.
func (s *Supervised) MountHeadIndex(path string) (absPath string, count int, diskSize int64, err error) {
	fn := func(c Client) error {
		absPath, count, diskSize, err = c.MountHeadIndex(path)
		return err
	}

	err = s.call(fn)
	return
}

// MountGetIndex calls registered Client's MountGetIndex method and returns its
// result if it's not produced by Disconnected client. If it is, this function
// will wait until valid client is available or timeout is reached.
func (s *Supervised) MountGetIndex(path string) (idx *index.Index, err error) {
	fn := func(c Client) error {
		idx, err = c.MountGetIndex(path)
		return err
	}

	err = s.call(fn)
	return
}

// Exec calls registered Client's Exec method and returns its result if
// it's not produced by Disconnected client. If it is, this function will wait
// until valid client is available or timeout is reached.
func (s *Supervised) Exec(req *os.ExecRequest) (resp *os.ExecResponse, err error) {
	fn := func(c Client) error {
		resp, err = c.Exec(req)
		return err
	}

	err = s.call(fn)
	return
}

// Kill calls registered Client's Kill method and returns its result if
// it's not produced by Disconnected client. If it is, this function will wait
// until valid client is available or timeout is reached.
func (s *Supervised) Kill(req *os.KillRequest) (resp *os.KillResponse, err error) {
	fn := func(c Client) error {
		resp, err = c.Kill(req)
		return err
	}

	err = s.call(fn)
	return
}

// Context calls registered Client's Context method and returns its result. If
// there is an error during client retrieving, this function will return
// canceled context.
func (s *Supervised) Context() context.Context {
	c, err := s.dcf()
	if err != nil {
		ctx, cancel := context.WithCancel(context.Background())
		cancel()
		return ctx
	}

	return c.Context()
}

func (s *Supervised) call(f func(Client) error) error {
	c, err := s.dcf()
	if err != nil {
		return err
	}

	ctx := c.Context()
	if err = f(c); err != ErrDisconnected {
		return err
	}

	// Wait for new client.
	ctx, cancel := context.WithTimeout(ctx, s.timeout)
	defer cancel()

	if <-ctx.Done(); ctx.Err() == context.DeadlineExceeded {
		// Client is still disconnected. Return it as is.
		return ErrDisconnected
	}

	// Previous context was canceled. This means that the client changed.
	c, err = s.dcf()
	if err != nil {
		return err
	}

	return f(c)
}
