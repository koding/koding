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
	StateFunc    func(int) (machinestate.State, error) // State checker function
	DesiredState machinestate.State

	Timeout        time.Duration // Global timeout to cancel the waiting
	PollerInterval time.Duration // Ticker interval to poll state changes
	Start, Finish  int           // Eventer progress bounds
}

// Wait calls the StateFunc with the specified interval and waits until it
// reached the desired state. It returns nil if the state has been reached
// successful.
func (w *WaitState) Wait() error {
	if w.Finish == 0 {
		w.Finish = 100
	}

	if w.PollerInterval == 0 {
		w.PollerInterval = 20 * time.Second
	}

	if w.Timeout == 0 {
		w.Timeout = 7 * time.Minute
	}

	if w.Start >= w.Finish {
		return errors.New("start value can't be lower than finish value")
	}

	timeout := time.After(w.Timeout)

	ticker := time.NewTicker(w.PollerInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			// add a delay of -10 so start doesn't get ever larger than finish
			if w.Start <= w.Finish-10 {
				w.Start += 10
			}

			state, err := w.StateFunc(w.Start)
			if err != nil {
				return err
			}

			if state == w.DesiredState {
				return nil
			}
		case <-time.After(time.Second * 30):
			// cancel the current ongoing process if it takes too long
			fmt.Println("Canceling current event asking")
			continue
		case <-timeout:
			return ErrWaitTimeout
		}
	}

}
