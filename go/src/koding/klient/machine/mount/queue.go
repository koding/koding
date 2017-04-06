package mount

import (
	"sync"

	"koding/klient/machine/index"
	msync "koding/klient/machine/mount/sync"
)

// Queue is a basic unbound FIFO queue based on a circular list that resizes as
// needed. This implementation was taken from:
//
//    https://gist.github.com/moraes/2141121
//
// There is also a dummy synchronization with a simple mutex and very simple,
// event priority aware logic.
//
// TODO(ppknap): this queue is unoptimized and should be rewritten.
type Queue struct {
	mu      sync.Mutex
	qHigh   *queue // high event priority queue.
	qMedium *queue // medium event priority queue.
	qLow    *queue // low event priority queue.
}

// NewQueue creates a new Queue object.
func NewQueue() *Queue {
	return &Queue{
		qHigh:   &queue{evs: make([]*msync.Event, 16)},
		qMedium: &queue{evs: make([]*msync.Event, 16)},
		qLow:    &queue{evs: make([]*msync.Event, 16)},
	}
}

// Push adds new event to the queue.
func (q *Queue) Push(ev *msync.Event) {
	q.mu.Lock()
	defer q.mu.Unlock()

	switch priority := ev.Change().Priority(); {
	case priority&index.PriorityHigh != 0:
		q.qHigh.Push(ev)
	case priority&index.PriorityMedium != 0:
		q.qMedium.Push(ev)
	default:
		q.qLow.Push(ev)
	}
}

// Size returns the number of events stored in queue.
func (q *Queue) Size() int {
	q.mu.Lock()
	defer q.mu.Unlock()

	return q.qHigh.count + q.qMedium.count + q.qLow.count
}

// Pop removes and returns an event from queue. If queue is empty, this function
// return nil.
func (q *Queue) Pop() (ev *msync.Event) {
	q.mu.Lock()
	defer q.mu.Unlock()

	if ev = q.qHigh.Pop(); ev != nil {
		return
	}
	if ev = q.qMedium.Pop(); ev != nil {
		return
	}

	return q.qLow.Pop()
}

type queue struct {
	evs   []*msync.Event
	head  int
	tail  int
	count int
}

// Push adds new event to the queue.
func (q *queue) Push(ev *msync.Event) {
	if q.head == q.tail && q.count > 0 {
		evs := make([]*msync.Event, len(q.evs)*2)
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

// Pop removes and returns an event from queue. If queue is empty, this function
// return nil.
func (q *queue) Pop() *msync.Event {
	if q.count == 0 {
		return nil
	}

	ev := q.evs[q.head]
	q.head = (q.head + 1) % len(q.evs)
	q.count--

	return ev
}
