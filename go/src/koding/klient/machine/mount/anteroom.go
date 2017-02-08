package mount

import (
	"context"
	"sync"
	"sync/atomic"
	"time"

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
		e.parent.detach(e.change.Name(), e.id)
		e.cancel()
	}
}

// Anteroom is a waiting room for synchronization requests. This structure
// manages index change events and safely distributes them to sync workers.
type Anteroom struct {
	queue   *Queue        // FIFO queue that stores events to be synced.
	evC     chan *Event   // Channel used to dequeue Events.
	wakeupC chan struct{} // Channel used to wake up dequeue go-routine.

	once   sync.Once
	closed bool          // set to true when the object was closed.
	stopC  chan struct{} // channel used to close queue dispatching go-routine.

	mu  sync.Mutex
	evs map[string]*Event // Change name to change event map.
}

// NewAnteroom creates a new Anteroom object. Once it's created, Close method
// must be called in order to GC allocated resources.
func NewAnteroom() *Anteroom {
	a := &Anteroom{
		queue:   NewQueue(),
		evC:     make(chan *Event),
		wakeupC: make(chan struct{}, 1),
		stopC:   make(chan struct{}),
		evs:     make(map[string]*Event),
	}

	go a.dequeue()

	return a
}

// Commit adds new change to the queue. If provided change already waits for
// synchronization its meta-data will be coalesced and the same context will
// be returned.
func (a *Anteroom) Commit(c *index.Change) context.Context {
	a.mu.Lock()
	defer a.mu.Unlock()

	// Return closed context when this object is no longer valid.
	if a.closed {
		ctx, cancel := context.WithCancel(context.Background())
		cancel()
		return ctx
	}

	ev, ok := a.evs[c.Name()]
	if !ok {
		// Event for the file doesn't exist. Add new one to evs and queue.
		ev = NewEvent(context.Background(), a, c)
		a.evs[c.Name()] = ev
		a.queue.Push(ev)
		a.wakeup()

		return ev.ctx
	}

	// Coalesce two changes. If they are similar, do nothing and wait for
	// them to be dequeued. If they are not and the event already left
	// the queue we mark them as invalid and add new event to the queue.
	// This logic prevents subtle data races like:
	//
	//   - file was added locally.
	//   - event was created, added to the queue and pop to the sync logic.
	//   - during synchronization, file was deleted.
	//   - delete event was created.
	//   - since sync is already processing the event which is still inside
	//     evs map, event will be coalesced to DL. However, it won't be
	//     re-added to the queue because it was already added by Add event.
	//     Thus, Delete event will be silently ignored.
	//
	if !index.Similar(ev.change.Coalesce(c).Meta(), ev.change.Meta()) {
		// If change was removed from the queue, mark it deprecated.
		if !atomic.CompareAndSwapUint64((*uint64)(&ev.stat), uint64(statusPop), uint64(statusDeprecated)) {
			return ev.ctx
		}

		// Change is deprecated. Re-push new change to the queue but keep
		// context from old event.
		newEv := NewEventCopy(ev)
		a.evs[c.Name()] = newEv
		a.queue.Push(newEv)
		a.wakeup()
	}

	return ev.ctx
}

// Events is a dispatcher for the queued events. The returned channel will be
// closed when Anteroom object is closed.
func (a *Anteroom) Events() <-chan *Event {
	return a.evC
}

// Status reports the current status of Anteroom object. The items value can
// be interpreted as a number of files waiting for synchronization. Comparing
// items and queued events shows how fast syncers are able to synchronize files.
func (a *Anteroom) Status() (items int, queued int) {
	a.mu.Lock()
	items = len(a.evs)
	a.mu.Unlock()

	return items, a.queue.Size()
}

// Close stops the dynamic client. After this function is called, client is
// in disconnected state and each contexts returned by it are closed.
func (a *Anteroom) Close() {
	a.once.Do(func() {
		a.mu.Lock()
		defer a.mu.Unlock()

		// Mark all events as deprecated and detach them from the queue.
		for name, ev := range a.evs {
			atomic.StoreUint64((*uint64)(&ev.stat), uint64(statusDeprecated))
			ev.cancel()

			delete(a.evs, name)
		}

		a.closed = true
		close(a.stopC) // Stop dispatching go-routine.
	})
}

// dequeue pops events from the queue and sends them to events channel.
func (a *Anteroom) dequeue() {
	var (
		ev  *Event
		evC chan *Event

		// wakeupTick ensures that dequeue will be always waked up. Even in case
		// we somehow miss the wakeup event. This is a safety fall-back.
		wakeupTick = time.NewTicker(30 * time.Second)
	)

	tryPop := func() {
		// Event haven't been sent yet.
		if ev != nil {
			return
		}

		if ev = a.queue.Pop(); ev == nil {
			evC = nil // queue is empty - turn off event channel.
		} else {
			atomic.StoreUint64((*uint64)(&ev.stat), uint64(statusPop))
			evC = a.evC // there is an event - turn on event channel.
		}
	}

	for {
		select {
		case evC <- ev:
			if ev = a.queue.Pop(); ev == nil {
				evC = nil // ueue is empty - turn off event channel.
			} else {
				atomic.StoreUint64((*uint64)(&ev.stat), uint64(statusPop))
			}
		case <-a.wakeupC:
			tryPop()
		case <-wakeupTick.C:
			tryPop()
		case <-a.stopC:
			wakeupTick.Stop()
			close(a.evC)
			return
		}
	}
}

// wakeup is a non-blocking attempt to wake up dequeue go-routine. Wakeup
// channel is buffered and no more than one wakeup event is needed to wakeup
// the dequeue loop so it's safe to drop excessive calls.
func (a *Anteroom) wakeup() {
	select {
	case a.wakeupC <- struct{}{}:
	default:
	}
}

// detach removes the change from coalescing events map only if stored id
// is equal to provided one.
func (a *Anteroom) detach(name string, id uint64) {
	a.mu.Lock()
	defer a.mu.Unlock()

	if ev, ok := a.evs[name]; ok && ev.ID() == id {
		delete(a.evs, name)
	}
}
