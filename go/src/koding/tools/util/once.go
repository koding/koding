package util

import (
	"sync"
	"sync/atomic"
)

// OnceSuccessful is like sync.Once, but keeps calling the function
// until it returns nil error.
type OnceSuccessful struct {
	mu   sync.Mutex
	done int32
}

// Do calls the fn only if it's being called for the first time or all
// the previous calls ended up with non-nil error.
func (o *OnceSuccessful) Do(fn func() error) error {
	if atomic.LoadInt32(&o.done) == 1 {
		return nil
	}
	o.mu.Lock()
	defer o.mu.Unlock()
	if o.done == 0 {
		if err := fn(); err != nil {
			return err
		}

		atomic.StoreInt32(&o.done, 1)
	}

	return nil
}
