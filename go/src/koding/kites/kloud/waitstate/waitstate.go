package waitstate

import (
	"errors"
	"fmt"
	"log"
	"time"

	"koding/kites/kloud/machinestate"
)

var ErrWaitTimeout = errors.New("timeout while waiting for state")

var MetaStates = map[string]MetaState{
	// we don't need to wait until it's terminated or stopped. So once we see
	// "terminating" or "terminated" (in case of destroy) we are actually done
	// because there is no going back anymore. Same applies for destroy
	"destroy": {
		[]machinestate.State{machinestate.Terminating, machinestate.Terminated},
		machinestate.Terminating,
	},
	"stop": {
		[]machinestate.State{machinestate.Stopping, machinestate.Stopped},
		machinestate.Stopping,
	},

	"build":           {[]machinestate.State{machinestate.Running}, machinestate.Building},
	"start":           {[]machinestate.State{machinestate.Running}, machinestate.Starting},
	"restart":         {[]machinestate.State{machinestate.Running}, machinestate.Rebooting},
	"create-snapshot": {[]machinestate.State{machinestate.Stopped}, machinestate.Pending},
	"create-volume":   {[]machinestate.State{machinestate.Stopped}, machinestate.Pending},
	"detach-volume":   {[]machinestate.State{machinestate.Stopped}, machinestate.Pending},
	"attach-volume":   {[]machinestate.State{machinestate.Stopped}, machinestate.Pending},
}

type MetaState struct {
	Desired []machinestate.State
	OnGoing machinestate.State
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
	metaState := MetaStates[w.Action]
	pollState := machinestate.Unknown

	for {
		select {
		// Poll less, push more.
		case <-eventTicker.C:
			if w.Start < w.Finish {
				w.Start += 2
			}

			if w.PushFunc != nil {
				w.PushFunc(fmt.Sprintf("%s called. Desired states: %v. Current state: %s",
					w.Action, metaState.Desired, metaState.OnGoing), w.Start, metaState.OnGoing)
			}

			if pollState.In(metaState.Desired...) {
				return nil
			}
		case <-pollTicker.C:
			// we don't return immediately once get an error. The poll duration
			// is already very high, so if we get a timeout or an InternalError
			// we just try again after Poll Interval. The timeout below will
			// care out that we are not stuck here infinitely.
			pollState, err = w.StateFunc(w.Start)
			if err != nil {
				log.Printf("waitstate: statefunc failed, trying again: %s", err)
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
