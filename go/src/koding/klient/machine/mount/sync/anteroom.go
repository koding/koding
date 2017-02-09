package sync

import (
	"context"
	"sync"
	"sync/atomic"
	"time"

	"koding/klient/machine/index"
)

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

	ev, ok := a.evs[c.Path()]
	if !ok {
		// Event for the file doesn't exist. Add new one to evs and queue.
		ev = NewEvent(context.Background(), a, c)
		a.evs[c.Path()] = ev
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
		a.evs[c.Path()] = newEv
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
		for path, ev := range a.evs {
			atomic.StoreUint64((*uint64)(&ev.stat), uint64(statusDeprecated))
			ev.cancel()

			delete(a.evs, path)
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
func (a *Anteroom) detach(path string, id uint64) {
	a.mu.Lock()
	defer a.mu.Unlock()

	if ev, ok := a.evs[path]; ok && ev.ID() == id {
		delete(a.evs, path)
	}
}
