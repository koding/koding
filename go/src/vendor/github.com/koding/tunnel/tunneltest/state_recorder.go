package tunneltest

import (
	"bytes"
	"fmt"
	"sync"
	"time"

	"github.com/koding/tunnel"
)

var (
	recWaitTimeout = 5 * time.Second
	recBuffer      = 32
)

// States is a sequence of client state changes.
type States []*tunnel.ClientStateChange

func (s States) String() string {
	if len(s) == 0 {
		return ""
	}

	var buf bytes.Buffer

	fmt.Fprintf(&buf, "[%s", s[0].String())

	for _, s := range s[1:] {
		fmt.Fprintf(&buf, ",%s", s.String())
	}

	buf.WriteRune(']')

	return buf.String()
}

// StateRecorder saves state changes pushed to StateRecorder.C().
type StateRecorder struct {
	mu       sync.Mutex
	ch       chan *tunnel.ClientStateChange
	recorded []*tunnel.ClientStateChange
	offset   int
}

func NewStateRecorder() *StateRecorder {
	rec := &StateRecorder{
		ch: make(chan *tunnel.ClientStateChange, recBuffer),
	}

	go rec.record()

	return rec
}

func (rec *StateRecorder) record() {
	for state := range rec.ch {
		rec.mu.Lock()
		rec.recorded = append(rec.recorded, state)
		rec.mu.Unlock()
	}
}

func (rec *StateRecorder) C() chan<- *tunnel.ClientStateChange {
	return rec.ch
}

func (rec *StateRecorder) WaitTransitions(states ...tunnel.ClientState) error {
	from := states[0]
	for _, to := range states[1:] {
		if err := rec.WaitTransition(from, to); err != nil {
			return err
		}

		from = to
	}

	return nil
}

func (rec *StateRecorder) WaitTransition(from, to tunnel.ClientState) error {
	timeout := time.After(recWaitTimeout)

	var lastStates []*tunnel.ClientStateChange
	for {
		select {
		case <-timeout:
			return fmt.Errorf("timed out waiting for %s->%s transition: %v", from, to, States(lastStates))
		default:
			time.Sleep(50 * time.Millisecond)

			lastStates = rec.States()[rec.offset:]

			for i, state := range lastStates {
				if from != 0 && state.Previous != from {
					continue
				}

				if to != 0 && state.Current != to {
					continue
				}

				rec.offset += i

				return nil
			}
		}
	}
}

func (rec *StateRecorder) States() []*tunnel.ClientStateChange {
	rec.mu.Lock()
	defer rec.mu.Unlock()

	states := make([]*tunnel.ClientStateChange, len(rec.recorded))
	copy(states, rec.recorded)
	return states
}
