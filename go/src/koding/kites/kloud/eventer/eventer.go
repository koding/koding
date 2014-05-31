package eventer

import (
	"sync"
	"time"
)

// Eventer is showing and managing a list of events.
type Eventer interface {
	// Push pushes the event to the top of the stack. It's needs to act as a
	// LIFO.
	Push(*Event)

	// Show shows the latest event in the stack. It does not remove it.
	// Consecutive calls may show the same content or other contents based on
	// the content of the stack.
	Show() *Event

	// Close closes the eventer and shuts down input to the stack. No other
	// events can be inserted after close is invoked. After close Pull should
	// show the latest item.
	Close()
}

type EventStatus int

const (
	Pending EventStatus = iota
	Finished
	Error
)

type Event struct {
	EventId     uint        `json:"eventID"`
	MachineId   string      `json:"machineID"`
	Message     string      `json:"message"`
	Status      EventStatus `json:"status"`
	LastUpdated time.Time   `json:"-"`
}

type Events struct {
	e         []*Event
	lastEvent Event
	closed    bool

	sync.Mutex
}

func New() *Events {
	return &Events{
		e: make([]*Event, 0),
	}
}

func (e *Events) Push(ev *Event) {
	e.Lock()
	defer e.Unlock()

	if e.closed {
		return
	}

	e.e = append(e.e, ev)
}

func (e *Events) Show() *Event {
	e.Lock()
	defer e.Unlock()

	return e.e[len(e.e)-1]
}

func (e *Events) Close() {
	e.Lock()
	defer e.Unlock()

	e.closed = true
	// e.e = e.e[len(e.e)-1:]
}

func (e *Events) String() string {
	var msg string
	for _, ev := range e.e {
		msg = msg + ev.Message + "\n"
	}

	return msg
}
