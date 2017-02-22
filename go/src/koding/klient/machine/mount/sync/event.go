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
		return "PUSH"
	case statusPop:
		return "POP_"
	case statusDeprecated:
		return "DEPR"
	case statusDone:
		return "DONE"
	}

	return "UNKN"
}

// Event wraps index change with context.Context. When more index.Changes arrive
// to anteroom, they are coalesced and have the same context.
type Event struct {
	id     uint64        // unique ID of the event.
	stat   status        // event status.
	parent *Anteroom     // parent structure used to detach event.
	change *index.Change // Index change to be synced.

	ctx    context.Context    // Context attached to stored change.
	cancel context.CancelFunc // Function that can close current context.
}

// NewEvent creates a new Event.
func NewEvent(ctx context.Context, parent *Anteroom, change *index.Change) *Event {
	ev := &Event{
		id:     atomic.AddUint64(&eventCounter, 1),
		stat:   statusPush,
		parent: parent,
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
		parent: ev.parent,
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
		if e.parent != nil {
			e.parent.detach(e.change.Path(), e.id)
		}
		e.cancel()
	}
}

// Context returns context associated with called event.
func (e *Event) Context() context.Context {
	return e.ctx
}

// String implements fmt.Stringer interface it pretty prints stored event.
func (e *Event) String() string {
	return status(atomic.LoadUint64((*uint64)(&e.stat))).String() + " " + e.change.String()
}
