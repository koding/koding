package machinegroup

import (
	"errors"
	"time"

	"koding/klient/machine/mount"

	"github.com/koding/kite/dnode"
)

// WaitIdleRequest is a request value of "machine.mount.waitIdle" kite method.
type WaitIdleRequest struct {
	Idetifier string         `json:"identifier,omitempty"`
	Path      string         `json:"path,omitempty"`
	Timeout   time.Duration  `json:"timeout,omitempty"`
	Done      dnode.Function `json:"done"` // func(bool)
}

// Valid implements the stack.Validator interface.
func (r *WaitIdleRequest) Valid() error {
	if r.Idetifier == "" && r.Path == "" {
		return errors.New("either non-empty identifier or path is required")
	}
	if !r.Done.IsValid() {
		return errors.New("done callback is not valid")
	}
	return nil
}

// WaitIdle is a handler implementation for "machine.mount.waitIdle" kite method.
func (g *Group) WaitIdle(r *WaitIdleRequest) error {
	id, err := g.lookupMountID(r)
	if err != nil {
		return err
	}

	m, err := g.sync.Sync(id)
	if err != nil {
		return err
	}

	c := make(chan bool, 1)

	m.Anteroom().IdleNotify(c, r.Timeout)

	go func() {
		r.Done.Call(<-c)
	}()

	return nil
}

// TODO(rjeczalik): Add LookupReuqest and use it in Exec / Kill methods as well.
func (g *Group) lookupMountID(r *WaitIdleRequest) (mount.ID, error) {
	if r.Idetifier != "" {
		if id, err := g.getMountID(r.Idetifier); err == nil {
			return id, nil
		}
	}

	id, _, err := g.lookup(r.Path)
	return id, err
}
