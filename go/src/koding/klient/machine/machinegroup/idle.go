package machinegroup

import (
	"errors"
	"time"

	"koding/klient/machine/mount"

	"github.com/koding/kite/dnode"
)

// WaitIdleRequest is a request value of "machine.mount.waitIdle" kite method.
type WaitIdleRequest struct {
	MountID mount.ID       `json:"mountID"`
	Timeout time.Duration  `json:"timeout,omitempty"`
	Done    dnode.Function `json:"done"` // func(bool)
}

// Valid implements the stack.Validator interface.
func (r *WaitIdleRequest) Valid() error {
	if r == nil {
		return errors.New("invalid nil request")
	}
	if !r.Done.IsValid() {
		return errors.New("done callback is not valid")
	}

	return nil
}

// WaitIdle is a handler implementation for "machine.mount.waitIdle" kite method.
func (g *Group) WaitIdle(r *WaitIdleRequest) error {
	if err := r.Valid(); err != nil {
		return err
	}

	sc, err := g.sync.Sync(r.MountID)
	if err != nil {
		return err
	}

	// If anteroom is paused, we need to start it for the synchronization period.
	switchBack := func() {}
	if sc.Anteroom().IsPaused() {
		var switchBackN int
		// Call Restore until Anterom is restored. This prevents unexpected
		// behavior when multiple processes manages mount synchronization.
		for sc.Anteroom().IsPaused() {
			switchBackN++
			sc.Anteroom().Resume()
		}

		switchBack = func() {
			for i := 0; i < switchBackN; i++ {
				sc.Anteroom().Pause()
			}
		}
	}

	c := make(chan bool, 1)

	sc.Anteroom().IdleNotify(c, r.Timeout)

	go func() {
		defer switchBack()
		r.Done.Call(<-c)
	}()

	return nil
}
