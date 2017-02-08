package sync

import (
	"sync"
)

// Queue is a basic unbound FIFO queue based on a circular list that resizes as
// needed. This implementation was taken from:
//
//    https://gist.github.com/moraes/2141121
//
// There is also a dummy synchronization with a simple mutex.
//
// TODO(ppknap): this queue is unoptimized and should be rewritten.
type Queue struct {
	mu    sync.Mutex
	evs   []*Event
	head  int
	tail  int
	count int
}

// NewQueue creates a new Queue object.
func NewQueue() *Queue {
	return &Queue{
		evs: make([]*Event, 16),
	}
}

// Push adds new event to the queue.
func (q *Queue) Push(ev *Event) {
	q.mu.Lock()
	defer q.mu.Unlock()

	if q.head == q.tail && q.count > 0 {
		evs := make([]*Event, len(q.evs)*2)
		copy(evs, q.evs[q.head:])
		copy(evs[len(q.evs)-q.head:], q.evs[:q.head])
		q.head = 0
		q.tail = len(q.evs)
		q.evs = evs
	}

	q.evs[q.tail] = ev
	q.tail = (q.tail + 1) % len(q.evs)
	q.count++
}

// Size returns the number of events stored in queue.
func (q *Queue) Size() int {
	q.mu.Lock()
	defer q.mu.Unlock()

	return q.count
}

// Pop removes and returns an event from queue. If queue is empty, this function
// return nil.
func (q *Queue) Pop() *Event {
	q.mu.Lock()
	defer q.mu.Unlock()

	if q.count == 0 {
		return nil
	}

	ev := q.evs[q.head]
	q.head = (q.head + 1) % len(q.evs)
	q.count--

	return ev
}
