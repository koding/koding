package eventer

import (
	"fmt"
	"sync"
	"time"

	"github.com/koding/kloud/machinestate"
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

	// Id returns the id for the given eventer
	Id() string

	// Close closes the eventer and shuts down input to the stack. No other
	// events can be inserted after close is invoked. After close Show() should
	// show the latest item.
	Close()
}

type Event struct {
	// EventId is the id of the whole processEventId is the id of the whole process
	EventId string `json:"eventId"`

	// Message explains the current event's behaviour/content.
	Message string `json:"message"`

	// Status defines the current state of the machine
	Status machinestate.State `json:"status"`

	// Percentage shows the current percentage of the whole event process
	Percentage int `json:"percentage"`

	// TimeStamp contains the last updated event time
	TimeStamp time.Time `json:"timeStamp"`
}

func (e *Event) String() string {
	return fmt.Sprintf("msg: %s, status: %s, timestamp: %s, percentage: %d",
		e.Message, e.Status, e.TimeStamp, e.Percentage)
}

type Events struct {
	events  []*Event
	eventId string
	closed  bool

	sync.Mutex
}

func New(id string) *Events {
	return &Events{
		events:  make([]*Event, 0),
		eventId: id,
	}
}

func (e *Events) Push(ev *Event) {
	e.Lock()
	defer e.Unlock()

	if e.closed {
		return
	}

	ev.EventId = e.eventId
	ev.TimeStamp = time.Now()

	e.events = append(e.events, ev)
}

func (e *Events) Show() *Event {
	e.Lock()
	defer e.Unlock()

	if len(e.events) == 0 {
		return &Event{
			EventId:   e.eventId,
			Message:   "no event available",
			TimeStamp: time.Now(),
			Status:    machinestate.Unknown,
		}
	}

	return e.events[len(e.events)-1]
}

func (e *Events) Close() {
	e.Lock()
	defer e.Unlock()

	e.closed = true
}

func (e *Events) Id() string {
	return e.eventId
}

func (e *Events) String() string {
	var msg string
	for _, ev := range e.events {
		msg = msg + ev.Message + "\n"
	}

	return msg
}
