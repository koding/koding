package kloud

import (
	"koding/kites/kloud/utils"
	"sync"
	"time"
)

// Eventer is showing and managing a list of events.
type Eventer interface {
	// Push pushes the event to the top of the stack. It's needs to act as a
	// LIFO.
	Push(*event)

	// Pull shows the latest event in the stack. It does not remove it.
	// Consecutive calls may show the same content or other contents based on
	// the content of the stack.
	Pull() *event

	// Close closes the eventer and shuts down input to the stack. No other
	// events can be inserted after close is invoked. After close Pull should
	// show the latest item.
	Close()
}

type event struct {
	eventId     uint      `json:"eventID"`
	machineId   string    `json:"machineID"`
	message     string    `json:"message"`
	lastUpdated time.Time `json:"-"`
}

type events struct {
	e      []*event
	closed bool

	sync.Mutex
}

func newEventer() Eventer {
	return &events{
		e: make([]*event, 0),
	}
}

func (e *events) Push(ev *event) {
	e.Lock()
	defer e.Unlock()

	if e.closed {
		return
	}

	e.e = append(e.e, ev)
}

func (e *events) Pull() *event {
	e.Lock()
	defer e.Unlock()

	return e.e[len(e.e)-1]
}

func (e *events) Close() {
	e.Lock()
	defer e.Unlock()

	e.closed = true
}

func (k *Kloud) NewEventer() (string, Eventer) {
	eventer := newEventer()
	eventId := utils.RandString(16)
	k.Eventers[eventId] = eventer

	return eventId, eventer
}
