package supervised

import (
	"context"
	"sync"
	"time"

	"koding/klient/machine/client"
	msync "koding/klient/machine/mount/sync"
)

// Builder is a factory for Supervised synchronization objects.
type Builder struct {
	Inner msync.Builder
}

// Build satisfies msync.Builder interface. It creates a new Supervised
// instance.
func (b *Builder) Build(opts *msync.BuildOpts) (msync.Syncer, error) {
	return NewSupervised(b.Inner, opts, 30*time.Second), nil
}

// Supervised satisfies msync.Syncer interface. It wraps other syncer and
// handles its build errors. When inner syncer builder fails, Supervised assumes
// that the failure is recoverable and waits for provided interval to rebuild
// the syncer.
type Supervised struct {
	b        msync.Builder
	opts     *msync.BuildOpts
	interval time.Duration

	once  sync.Once
	stopC chan struct{} // channel used to close any opened exec streams.
}

// NewSupervised creates a new Supervised object.
func NewSupervised(b msync.Builder, opts *msync.BuildOpts, interval time.Duration) *Supervised {
	return &Supervised{
		b:        b,
		opts:     opts,
		interval: interval,
		stopC:    make(chan struct{}),
	}
}

// ExecStream streams synchronization events from inner Syncers when they are
// available.
func (s *Supervised) ExecStream(evC <-chan *msync.Event) <-chan msync.Execer {
	exC := make(chan msync.Execer)
	opts := *s.opts // Shallow copy.

	// First create cancalled contex which will trigger first select in loop
	// bellow.
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	// Wrap provided client function in order to get context that other Syncers
	// used to initialize themselves.
	opts.ClientFunc = func() (client.Client, error) {
		c, err := s.opts.ClientFunc()
		if err != nil {
			return nil, err
		}
		ctx = c.Context()

		return c, nil
	}

	go func() {
		defer close(exC)

		var (
			sy     msync.Syncer
			exDynC <-chan msync.Execer
		)

		// Rebuild can be triggered by either exDynC channel or closed context.
		// The goal of this function is to rebuild the syncer. In case of error
		// other than disconnected this function will be repeated after provided
		// interval.
		rebuild := func() {
			var err error
			if sy, err = s.b.Build(&opts); err != nil {
				sy, exDynC = nil, nil
				return
			}
			exDynC = sy.ExecStream(evC) // Consume from new syncer.
		}

		for {
			select {
			case ex, ok := <-exDynC:
				if !ok {
					rebuild()
					break
				}

				select {
				case exC <- ex:
				case <-s.stopC:
					if sy != nil {
						sy.Close()
					}
					return
				}
			case <-ctx.Done():
				ctx, _ = context.WithTimeout(context.Background(), s.interval)
				if sy == nil {
					rebuild()
				} else {
					sy.Close()
				}
			case <-s.stopC:
				if sy != nil {
					sy.Close()
				}
				return
			}
		}
	}()

	return exC
}

// Close stops all created synchronization streams.
func (s *Supervised) Close() error {
	s.once.Do(func() {
		close(s.stopC)
	})

	return nil
}
