package rsync

import (
	"context"
	"fmt"
	"os/exec"
	"sync"

	msync "koding/klient/machine/mount/sync"
)

// Builder is a factory for rsync-based synchronization objects.
type Builder struct{}

// Build satisfies msync.Builder interface. It produces Rsync objects from a
// given options if rsync executable is present in $PATH.
func (Builder) Build(opts *msync.BuildOpts) (msync.Syncer, error) {
	if _, err := exec.LookPath("rsync"); err != nil {
		return nil, fmt.Errorf("rsync: %v", err)
	}

	return NewRsync(), nil
}

// Event is a no-op for synchronization object.
// TODO
type Event struct {
	ev *msync.Event
}

// Exec satisfies msync.Execer interface.
// TODO
func (e *Event) Exec() error {
	e.ev.Done()

	return nil
}

// String implements fmt.Stringer interface. It pretty prints internal event.
func (e *Event) String() string {
	return e.ev.String() + " - " + "rsynced"
}

// Rsync uses rsync(1) file-copying tool to provide synchronization between
// remote and local files.
type Rsync struct {
	Cmd func(ctx context.Context, args ...string) *exec.Cmd // Comand factory.

	once  sync.Once
	stopC chan struct{} // channel used to close any opened exec streams.
}

// NewRsync creates a new Rsync synchronization object.
func NewRsync() *Rsync {
	return &Rsync{
		Cmd: func(ctx context.Context, args ...string) *exec.Cmd {
			return exec.CommandContext(ctx, "rsync", args...)
		},

		stopC: make(chan struct{}),
	}
}

// ExecStream wraps incoming msync events with Rsync event logic that is
// responsible for invoking rsync process and ensuring final index state.
func (r *Rsync) ExecStream(evC <-chan *msync.Event) <-chan msync.Execer {
	exC := make(chan msync.Execer)

	go func() {
		defer close(exC)
		for {
			select {
			case ev, ok := <-evC:
				if !ok {
					return
				}

				ex := &Event{ev: ev}
				select {
				case exC <- ex:
				case <-r.stopC:
					return
				}
			case <-r.stopC:
				return
			}
		}
	}()

	return exC
}

// Close stops all created synchronization streams.
func (r *Rsync) Close() error {
	r.once.Do(func() {
		close(r.stopC)
	})

	return nil
}
