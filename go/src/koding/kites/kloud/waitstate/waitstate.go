package waitstate

import (
	"errors"
	"fmt"
	"time"

	"koding/kites/kloud/machinestate"
)

var ErrWaitTimeout = errors.New("timeout while waiting for state")

// WaitState is used to track the state of a given process.
type WaitState struct {
	StateFunc       func(int) (machinestate.State, error)
	DesiredState    machinestate.State
	Timeout         time.Duration
	EventerInterval time.Duration
	PollerInterval  time.Duration
	Start, Finish   int
}

// Wait calls the StateFunc with the specified interval and waits until it
// reached the desired state. It returns nil if the state has been reached
// successfull.
func (w *WaitState) Wait() error {
	if w.Finish == 0 {
		w.Finish = 100
	}

	if w.EventerInterval == 0 {
		w.EventerInterval = 3 * time.Second
	}

	if w.PollerInterval == 0 {
		w.PollerInterval = 30 * time.Second
	}

	if w.Timeout == 0 {
		w.Timeout = 7 * time.Minute
	}

	timeout := time.After(w.Timeout)

	eventTicker := time.NewTicker(w.EventerInterval)
	pollTicker := time.NewTicker(w.PollerInterval)
	defer eventTicker.Stop()
	defer pollTicker.Stop()

	var err error
	var state machinestate.State

	for {
		select {
		case <-eventTicker.C:
			if w.Start < w.Finish {
				w.Start += 2
			}
			if state == w.DesiredState {
				return nil
			}
		// Poll less, send events more.
		case <-pollTicker.C:
			state, err = w.StateFunc(w.Start)
			if err != nil {
				return err
			}
		case <-time.After(time.Second * 40):
			// cancel the current ongoing process if it takes to long
			fmt.Println("Canceling current event asking")
			continue
		case <-timeout:
			return ErrWaitTimeout
		}
	}

}
