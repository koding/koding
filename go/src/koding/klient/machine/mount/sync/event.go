package sync

import (
	"context"
	"sync/atomic"

	"koding/klient/machine/index"
)

// eventCounter stores the current event ID number.
var eventCounter uint64

// status describes event status.
type status uint64

const (
	statusPush       status = 1 + iota // Event was added to queue.
	statusPop                          // Event was removed from queue.
	statusDeprecated                   // Event is no longer valid.
	statusDone                         // Event is completed.
)

// String returns textual representation of event status.
func (s status) String() string {
	switch s {
	case statusPush:
		return "push"
	case statusPop:
		return "pop"
	case statusDeprecated:
		return "deprecated"
	case statusDone:
		return "done"
	}

	return "unknown"
}

// Finalizer is an interface used by Event to clean its resources from event
// storage. The event calls it when is no longer needed.
type Finalizer interface {
	// Detach detach is called by non deprecated events.
	Detach(path string, id uint64)

	// Unsync is called by deprecated events.
	Unsync(path string)
}

// Event wraps index change with context.Context.
type Event struct {
	id     uint64        // unique ID of the event.
	stat   status        // event status.
	fin    Finalizer     // finalized used to detach events.
	change *index.Change // Index change to be synced.

	ctx    context.Context    // Context attached to stored change.
	cancel context.CancelFunc // Function that can close current context.
}

// NewEvent creates a new Event.
func NewEvent(ctx context.Context, fin Finalizer, change *index.Change) *Event {
	ev := &Event{
		id:     atomic.AddUint64(&eventCounter, 1),
		stat:   statusPush,
		fin:    fin,
		change: change,
	}
	ev.ctx, ev.cancel = context.WithCancel(ctx)

	return ev
}

// NewEventCopy creates a new Event based on data from provided object. It
// assigns new ID and Push status to returned Event.
func NewEventCopy(ev *Event) *Event {
	return &Event{
		id:     atomic.AddUint64(&eventCounter, 1),
		stat:   statusPush,
		fin:    ev.fin,
		change: ev.change,
		ctx:    ev.ctx,
		cancel: ev.cancel,
	}
}

// Change returns index change stored by the event. It is safe to use returned
// change concurrently.
func (e *Event) Change() *index.Change {
	return e.change
}

// ID returns a unique identifier of the event.
func (e *Event) ID() uint64 {
	return atomic.LoadUint64((*uint64)(&e.id))
}

// Valid indicates whether event is still valid. If it's not, calling Done
// method is not necessary
func (e *Event) Valid() bool {
	return atomic.LoadUint64((*uint64)(&e.stat)) < uint64(statusDeprecated)
}

// Done must be called on event when it's no longer needed. It indicates that
// event should be GC if it haven't been yet.
func (e *Event) Done() {
	if atomic.SwapUint64((*uint64)(&e.stat), uint64(statusDone)) != uint64(statusDeprecated) {
		if e.fin != nil {
			e.fin.Detach(e.change.Path(), e.id)
		}
		e.cancel()
	} else if e.fin != nil {
		e.fin.Unsync(e.change.Path())
	}
}

// Pop marks event as removed from the queue.
func (e *Event) Pop() {
	atomic.StoreUint64((*uint64)(&e.stat), uint64(statusPop))
}

// Deprecate marks event deprecated.
func (e *Event) Deprecate() {
	atomic.StoreUint64((*uint64)(&e.stat), uint64(statusDeprecated))
	e.cancel()
}

// DeprecateIfPop deprecates the Event only when it's removed from the queue.
// if it is not, this function returns false.
func (e *Event) DeprecateIfPop() bool {
	return atomic.CompareAndSwapUint64((*uint64)(&e.stat), uint64(statusPop), uint64(statusDeprecated))
}

// Context returns context associated with called event.
func (e *Event) Context() context.Context {
	return e.ctx
}

// String implements fmt.Stringer interface it pretty prints stored event.
func (e *Event) String() string {
	return status(atomic.LoadUint64((*uint64)(&e.stat))).String() + " " + e.change.String()
}
