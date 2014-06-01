package eventer

import (
	"strings"
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

	// Id returns the id for the given eventer
	Id() string

	// Close closes the eventer and shuts down input to the stack. No other
	// events can be inserted after close is invoked. After close Show() should
	// show the latest item.
	Close()
}

type EventStatus int

const (
	Pending EventStatus = iota
	Finished
	Error
)

var EventStatuses = map[string]EventStatus{
	"PENDING":  Pending,
	"FINISHED": Finished,
	"ERROR":    Error,
}

func (e *EventStatus) MarshalJSON() ([]byte, error) {
	return []byte(`"` + e.String() + `"`), nil
}

func (e *EventStatus) UnmarshalJSON(d []byte) error {
	// comes as `"PENDING"`,  will convert to: `PENDING`
	unquoted := strings.Replace(string(d), "\"", "", -1)

	*e = EventStatuses[unquoted]
	return nil
}

func (e EventStatus) String() string {
	switch e {
	case Pending:
		return "PENDING"
	case Finished:
		return "FINISHED"
	case Error:
		return "ERROR"
	default:
		return "UNKNOWN_EVENT_STATUS"
	}
}

type Event struct {
	EventId     string      `json:"eventID"`
	Message     string      `json:"message"`
	Status      EventStatus `json:"status"`
	LastUpdated time.Time   `json:"-"`
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
	ev.LastUpdated = time.Now()

	e.events = append(e.events, ev)
}

func (e *Events) Show() *Event {
	e.Lock()
	defer e.Unlock()

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
