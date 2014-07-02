package waitstate

import (
	"errors"
	"fmt"
	"koding/kites/kloud/kloud/machinestate"
	"time"
)

var ErrWaitTimeout = errors.New("timeout while waiting for state")

// WaitState is used to track the state of a given process.
type WaitState struct {
	StateFunc    func() (machinestate.State, error)
	DesiredState machinestate.State
	Timeout      time.Duration
	Interval     time.Duration
}

// Wait calls the StateFunc with the specified interval and waits until it
// reached the desired state. It returns nil if the state has been reached
// successfull.
func (w *WaitState) Wait() error {
	timeout := time.After(w.Timeout)
	ticker := time.Tick(w.Interval)
	for {
		select {
		case <-ticker:
			state, err := w.StateFunc()
			if err != nil {
				return err
			}

			if state == w.DesiredState {
				return nil
			}
		case <-time.After(time.Second * 10):
			// cancel the current ongoing process
			fmt.Println("Canceling current event asking")
			continue
		case <-timeout:
			return ErrWaitTimeout
		}
	}

}
