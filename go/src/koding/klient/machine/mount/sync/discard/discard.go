package discard

import (
	"sync"

	msync "koding/klient/machine/mount/sync"
)

// Builder is a factory for Discard synchronization objects.
type Builder struct{}

// Build satisfies msync.Builder interface. It produces Discard objects and
// always returns nil error.
func (Builder) Build(_ *msync.BuildOpts) (msync.Syncer, error) {
	return NewDiscard(), nil
}

// Event is a no-op for synchronization object.
type Event struct {
	ev *msync.Event
}

// Event returns base event which is going to be synchronized.
func (e *Event) Event() *msync.Event {
	return e.ev
}

// Exec satisfies msync.Execer interface. The only thing this method does is
// closing internal sync event.
func (e *Event) Exec() error {
	e.ev.Done()

	return nil
}

// Debug always returns empty string for discard execer.
func (e *Event) Debug() string {
	return ""
}

// String implements fmt.Stringer interface. It pretty prints internal event.
func (e *Event) String() string {
	return e.ev.String() + " (discarded)"
}

// Discard is a no-op synchronization object. It can be used as a stub for other
// non-event-dependent logic. This means that this type should be used only in
// tests which don't care about mount file synchronization.
type Discard struct {
	once  sync.Once
	stopC chan struct{} // channel used to close any opened exec streams.
}

// NewDiscard creates a new Discard synchronization object.
func NewDiscard() *Discard {
	return &Discard{
		stopC: make(chan struct{}),
	}
}

// ExecStream wraps incoming msync events with discard event logic which is
// basically a no-op.
func (d *Discard) ExecStream(evC <-chan *msync.Event) <-chan msync.Execer {
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
				case <-d.stopC:
					ex.ev.Done()
					return
				}
			case <-d.stopC:
				return
			}
		}
	}()

	return exC
}

// Close stops all created synchronization streams.
func (d *Discard) Close() error {
	d.once.Do(func() {
		close(d.stopC)
	})

	return nil
}
