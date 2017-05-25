package mount

import (
	"context"
	"sync"
	"sync/atomic"
	"time"

	"koding/klient/machine/index"
	msync "koding/klient/machine/mount/sync"
)

// Anteroom is a waiting room for synchronization requests. This structure
// manages index change events and safely distributes them to sync workers.
type Anteroom struct {
	queue   *Queue            // FIFO queue that stores events to be synced.
	evC     chan *msync.Event // Channel used to dequeue Events.
	wakeupC chan struct{}     // Channel used to wake up dequeue go-routine.

	once   sync.Once
	closed bool          // set to true when the object was closed.
	stopC  chan struct{} // channel used to close queue dispatching go-routine.

	paused int64 // stops dequeue when non-zero.

	evsMu sync.Mutex
	evs   map[string]*msync.Event // Change name to change event map.

	cursMu sync.Mutex
	curs   map[string]*pendingEvent // Paths currently processed.

	synced int64        // How many events are processing.
	idle   *subscribers // Subscribers waiting for idle signals.
}

// pendingEvent describes pending event. It can only be sent to receiver worker
// if ready flag is set to true.
type pendingEvent struct {
	ev    *msync.Event
	ready bool
}

// NewAnteroom creates a new Anteroom object. Once it's created, Close method
// must be called in order to GC allocated resources.
func NewAnteroom() *Anteroom {
	stopC := make(chan struct{})

	a := &Anteroom{
		queue:   NewQueue(),
		evC:     make(chan *msync.Event),
		wakeupC: make(chan struct{}, 1),
		stopC:   stopC,
		evs:     make(map[string]*msync.Event),
		curs:    make(map[string]*pendingEvent),
		idle:    newSubscribers(stopC),
	}

	go a.dequeue()

	return a
}

// Commit adds new change to the queue. If provided change already waits for
// synchronization its meta-data will be coalesced and the same context will
// be returned.
func (a *Anteroom) Commit(c *index.Change) context.Context {
	a.evsMu.Lock()
	defer a.evsMu.Unlock()

	// Return closed context when this object is no longer valid.
	if a.closed {
		ctx, cancel := context.WithCancel(context.Background())
		cancel()
		return ctx
	}

	ev, ok := a.evs[c.Path()]
	if !ok {
		// Event for the file doesn't exist. Add new one to evs and queue.
		ev = msync.NewEvent(context.Background(), a, c)
		a.evs[c.Path()] = ev
		a.queue.Push(ev)
		a.wakeup()

		return ev.Context()
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
	if !index.Similar(ev.Change().Coalesce(c).Meta(), ev.Change().Meta()) {
		// If change was removed from the queue, mark it deprecated.
		if !ev.DeprecateIfPop() {
			return ev.Context()
		}

		// Change is deprecated. Re-push new change to the queue but keep
		// context from old event.
		newEv := msync.NewEventCopy(ev)
		a.evs[c.Path()] = newEv
		a.queue.Push(newEv)
		a.wakeup()
	}

	return ev.Context()
}

// Events is a dispatcher for the queued events. The returned channel will be
// closed when Anteroom object is closed.
func (a *Anteroom) Events() <-chan *msync.Event {
	return a.evC
}

// Status reports the current status of Anteroom object. The items value can
// be interpreted as a number of files waiting for synchronization. Comparing
// items and queued events shows how fast syncers are able to synchronize files.
func (a *Anteroom) Status() (items int, synced int) {
	a.evsMu.Lock()
	items = len(a.evs)
	synced = int(atomic.LoadInt64(&a.synced))
	a.evsMu.Unlock()

	if a.IsPaused() {
		synced = -2
	}

	return items, synced
}

// Close stops the dynamic client. After this function is called, client is
// in disconnected state and each contexts returned by it are closed.
func (a *Anteroom) Close() error {
	a.once.Do(func() {
		a.evsMu.Lock()
		defer a.evsMu.Unlock()

		// Mark all events as deprecated and detach them from the queue.
		for path, ev := range a.evs {
			ev.Deprecate()
			delete(a.evs, path)
		}

		a.closed = true
		close(a.stopC) // Stop dispatching go-routine.
	})

	return nil
}

// IdleNotify makes Anteroom send a true value to c when it has no
// more events to process - becomes idle.
//
// If Anteroom is already idle, it sends true to c right away.
//
// All the sends are non-blocking, the caller must ensure that c has
// sufficient buffer space to receive value.
//
// If timeout is non-zero, Anteroom will send false to c if
// waiting for idle signal exceeds the timeout.
//
// Anteroom sends value in a one-shot manner and it does not
// close c - once c received value, it can be reused to receive
// another one with second IdleNotify call.
func (a *Anteroom) IdleNotify(c chan<- bool, timeout time.Duration) {
	a.evsMu.Lock()
	defer a.evsMu.Unlock()

	if atomic.LoadInt64(&a.synced) == 0 && len(a.evs) == 0 {
		select {
		case c <- true:
		default:
		}
		return
	}
	a.idle.add(c, timeout)
}

// IdleStop undeos the effect of prior call to IdleNotify.
//
// If c awaits for Anteroom to be idle, it will receive
// false value once stopped.
func (a *Anteroom) IdleStop(c chan<- bool) {
	a.idle.del(c)
}

// dequeue pops events from the queue and sends them to events channel.
func (a *Anteroom) dequeue() {
	var (
		ev  *msync.Event
		evC chan *msync.Event

		// wakeupTick ensures that dequeue will be always waked up. Even in case
		// we somehow miss the wakeup event. This is a safety fall-back.
		wakeupTick = time.NewTicker(30 * time.Second)
	)

	// Pop event from the queue. If received event is present in current
	// processed map, the event must be stopped until already sent one is
	// executed. This prevents situations where two parallel workers executes
	// different changes on the same file.
	pop := func() *msync.Event {
		a.cursMu.Lock()
		defer a.cursMu.Unlock()

		// Pop any pending events.
		for path, pev := range a.curs {
			if pev != nil && pev.ready {
				a.curs[path] = nil
				return pev.ev
			}
		}

		for {
			ev := a.queue.Pop()
			if ev == nil {
				return nil
			}

			switch pending, ok := a.curs[ev.Change().Path()]; {
			case ok && pending != nil:
				// Event is pending so it could not be in Pop state. Commit
				// logic makes this branch impossible since events in queue
				// are coalesced.
				panic("duplicated event received from waiting queue" + ev.String())
			case ok && pending == nil:
				// Similar event is already processed by worker go-routine.
				// Store new one as pending.
				a.curs[ev.Change().Path()] = &pendingEvent{
					ev:    ev,
					ready: false,
				}
			case !ok:
				// There are no similar events being processed. Mark current one
				// as sent to workers.
				a.curs[ev.Change().Path()] = nil
				return ev
			}
		}
	}

	tryPop := func() {
		// If anteroom is paused, don't process the events.
		if a.IsPaused() {
			return
		}

		// Event haven't been sent yet.
		if ev != nil {
			return
		}

		if ev = pop(); ev == nil {
			evC = nil // queue is empty - turn off event channel.
		} else {
			atomic.AddInt64(&a.synced, 1)
			ev.Pop()
			evC = a.evC // there is an event - turn on event channel.
		}
	}

	for {
		select {
		case evC <- ev:
			if a.IsPaused() {
				ev, evC = nil, nil // paused - turn off event channel.
				return
			}

			if ev = pop(); ev == nil {
				evC = nil // queue is empty - turn off event channel.
			} else {
				atomic.AddInt64(&a.synced, 1)
				ev.Pop()
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

// Detach removes the change from coalescing events map only if stored id
// is equal to provided one.
func (a *Anteroom) Detach(path string, id uint64) {
	a.evsMu.Lock()
	defer a.evsMu.Unlock()

	if ev, ok := a.evs[path]; ok && ev.ID() == id {
		delete(a.evs, path)
		a.unsync(path)
	}
}

// Unsync is called by event which is considered done.
func (a *Anteroom) Unsync(path string) {
	a.evsMu.Lock()
	defer a.evsMu.Unlock()

	a.unsync(path)
}

func (a *Anteroom) unsync(path string) {
	if atomic.AddInt64(&a.synced, -1) == 0 && len(a.evs) == 0 {
		a.idle.done(true)
	}

	// Remove event from currently processed ones.
	a.cursMu.Lock()
	if pev, ok := a.curs[path]; ok {
		if pev != nil {
			pev.ready = true
		} else {
			delete(a.curs, path)
		}
	}
	a.cursMu.Unlock()

	a.wakeup()
}

// Pause prevets Anteroom from sending new events.
func (a *Anteroom) Pause() {
	atomic.StoreInt64(&a.paused, 1)
	a.idle.done(false)
}

// Resume resumes anteroom when it's paused.
func (a *Anteroom) Resume() {
	atomic.StoreInt64(&a.paused, -1)
	a.wakeup()
}

// IsPaused indicates whether Anteroom is paused or not.
func (a *Anteroom) IsPaused() bool {
	return atomic.LoadInt64(&a.paused) > 0
}

type subscriber struct {
	c chan<- bool
	t *time.Timer
}

type subscribers struct {
	mu   sync.Mutex
	subs map[chan<- bool]subscriber
}

func newSubscribers(stopC <-chan struct{}) *subscribers {
	s := &subscribers{
		subs: make(map[chan<- bool]subscriber),
	}

	go func() {
		<-stopC
		s.done(false)
	}()

	return s
}

func (s *subscribers) add(c chan<- bool, d time.Duration) {
	s.mu.Lock()
	if _, ok := s.subs[c]; !ok {
		sub := subscriber{c: c}
		if d != 0 {
			sub.t = time.AfterFunc(d, func() { s.del(c) })
		}
		s.subs[c] = sub
	}
	s.mu.Unlock()
}

func (s *subscribers) del(c chan<- bool) {
	s.mu.Lock()
	if sub, ok := s.subs[c]; ok {
		if sub.t != nil {
			sub.t.Stop()
		}
		select {
		case sub.c <- false:
		default:
		}
		delete(s.subs, c)
	}
	s.mu.Unlock()
}

func (s *subscribers) done(ok bool) {
	s.mu.Lock()
	subs := s.subs
	s.subs = make(map[chan<- bool]subscriber)
	s.mu.Unlock()

	for _, sub := range subs {
		if sub.t != nil {
			sub.t.Stop()
		}
		select {
		case sub.c <- ok:
		default:
		}
	}
}
