package waitstate

import (
	"errors"
	"fmt"
	"time"

	"github.com/koding/kloud/machinestate"
)

var ErrWaitTimeout = errors.New("timeout while waiting for state")

// WaitState is used to track the state of a given process.
type WaitState struct {
	StateFunc     func(int) (machinestate.State, error)
	DesiredState  machinestate.State
	Timeout       time.Duration
	Interval      time.Duration
	Start, Finish int
}

// Wait calls the StateFunc with the specified interval and waits until it
// reached the desired state. It returns nil if the state has been reached
// successfull.
func (w *WaitState) Wait() error {
	if w.Start == 0 || w.Finish == 0 {
		return errors.New("start and finish needs to be initalized")
	}

	if w.Interval == 0 {
		w.Interval = 3 * time.Second
	}

	if w.Timeout == 0 {
		w.Timeout = 7 * time.Minute
	}

	timeout := time.After(w.Timeout)
	ticker := time.Tick(w.Interval)

	for {
		select {
		case <-ticker:
			if w.Start < w.Finish {
				w.Start += 2
			}

			state, err := w.StateFunc(w.Start)
			if err != nil {
				return err
			}

			if state == w.DesiredState {
				return nil
			}
		case <-time.After(time.Second * 5):
			// cancel the current ongoing process if it takes to long
			fmt.Println("Canceling current event asking")
			continue
		case <-timeout:
			return ErrWaitTimeout
		}
	}

}
