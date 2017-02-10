package clienttest

import (
	"context"
	"fmt"
	"sync/atomic"

	"koding/klient/machine/client"
	"koding/klient/machine/index"
)

type invCounter int64

func (ic invCounter) Error() string {
	return fmt.Sprintf("count number is %v", ic)
}

// CountNumber retrieves the number of Counter calls from provided error. If
// error doesn't have the correct type, -1 is returned.
func CountNumber(err error) int {
	if ic, ok := err.(invCounter); ok {
		return int(ic)
	}

	return -1
}

// Counter satisfies machine.Client interface. It counts all method invocations
// and returns the current number in function error. The actual number can be
// obtained by calling CountNumber function on received error.
type Counter struct {
	curr int64
}

var _ client.Client = (*Counter)(nil)

// CurrentUser increases function call counter and returns it as an error.
func (c *Counter) CurrentUser() (string, error) {
	return "", invCounter(atomic.AddInt64(&c.curr, 1))
}

// SSHAddKeys increases function call counter and returns it as an error.
func (c *Counter) SSHAddKeys(_ string, _ ...string) error {
	return invCounter(atomic.AddInt64(&c.curr, 1))
}

// MountHeadIndex increases function call counter and returns it as an error.
func (c *Counter) MountHeadIndex(path string) (string, int, int64, error) {
	return "", 0, 0, invCounter(atomic.AddInt64(&c.curr, 1))
}

// MountGetIndex increases function call counter and returns it as an error.
func (c *Counter) MountGetIndex(path string) (*index.Index, error) {
	return nil, invCounter(atomic.AddInt64(&c.curr, 1))
}

// DiskBlocks increases function call counter and returns it as an error.
func (c *Counter) DiskBlocks(path string) (size, total, free, used uint64, err error) {
	return 0, 0, 0, 0, invCounter(atomic.AddInt64(&c.curr, 1))
}

// Context increases function call counter and returns background context.
func (c *Counter) Context() context.Context {
	atomic.AddInt64(&c.curr, 1)
	return context.Background()
}

// Counts returns the current state of counter.
func (c *Counter) Counts() int {
	return int(atomic.LoadInt64(&c.curr))
}
