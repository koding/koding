package waitstate

import (
	"errors"
	"fmt"
	"time"

	"koding/kites/kloud/machinestate"
)

var ErrWaitTimeout = errors.New("timeout while waiting for state")

var MetaState = map[string]struct{ Desired, OnGoing machinestate.State }{
	"build": {machinestate.Running, machinestate.Building},

	// we don't need to wait until it's terminated. So once we see
	// "terminating" we are actually done because there is no going back
	// anymore.
	"destroy": {machinestate.Terminating, machinestate.Terminating},

	"start": {machinestate.Running, machinestate.Starting},

	// we don't need to wait until it's bein stoped. So once we see
	// "stopping" we are actually done because there is no going back
	// anymore.
	"stop": {machinestate.Stopping, machinestate.Stopping},

	"restart":         {machinestate.Running, machinestate.Rebooting},
	"create-snapshot": {machinestate.Stopped, machinestate.Pending},
	"create-volume":   {machinestate.Stopped, machinestate.Pending},
	"detach-volume":   {machinestate.Stopped, machinestate.Pending},
	"attach-volume":   {machinestate.Stopped, machinestate.Pending},
}

// WaitState is used to track the state of a given process.
type WaitState struct {
	StateFunc       func(int) (machinestate.State, error) // State checker function
	PushFunc        func(string, int, machinestate.State) // Event pusher function
	Action          string                                // Request of action to change states
	Timeout         time.Duration                         // Global timeout to cancel the waiting
	EventerInterval time.Duration                         // Ticker interval to push events
	PollerInterval  time.Duration                         // Ticker interval to poll state changes
	Start, Finish   int                                   // Eventer progress bounds
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
		w.PollerInterval = 20 * time.Second
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
	metaState := MetaState[w.Action]
	pollState := machinestate.Unknown

	for {
		select {
		// Poll less, push more.
		case <-eventTicker.C:
			if w.Start < w.Finish {
				w.Start += 2
			}

			if w.PushFunc != nil {
				w.PushFunc(fmt.Sprintf("%s called. Desired state: %s. Current state: %s",
					w.Action, metaState.Desired, metaState.OnGoing), w.Start, metaState.OnGoing)
			}

			if pollState == metaState.Desired {
				return nil
			}
		// Poll less, push more.
		case <-pollTicker.C:
			pollState, err = w.StateFunc(w.Start)
			if err != nil {
				return err
			}
		case <-time.After(time.Second * 40):
			// cancel the current ongoing process if it takes too long
			fmt.Println("Canceling current event asking")
			continue
		case <-timeout:
			return ErrWaitTimeout
		}
	}

}
