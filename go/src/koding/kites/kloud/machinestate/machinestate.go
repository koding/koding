// Package machinestate defines the lifecycle of a machine with states.
package machinestate

import (
	"fmt"
	"strings"
)

// State defines the Machines state
type State int

const (
	// Unknown is a state that needs to be resolved manually
	Unknown State = iota

	// NotInitialzed defines a state where the machine instance does not exists
	// and was not built once. It's waits to be initialized
	NotInitialized

	// Building is in progress of creating the machine A successful Booting
	// state results in a Running state.
	Building

	// Starting defines the state where the machine is booting. A succesfull
	// Starting state results in a Running state.
	Starting

	// Running defines the state where the machine is running.
	Running

	// Stopping is in progress of stopping the machine. A succesfull Stopping
	// state results in a Stopped state.
	Stopping

	// Stopped defines the state where the machine is stopped and turned of.
	Stopped

	// Rebooting defines the state where the machine is rebooting. A succesfull
	// Rebooting state results in a Running state.
	Rebooting

	// Terminating defines the state where the machine is being terminated. A
	// succesfull Terminating state results in a Terminated state.
	Terminating

	// Terminated defines the state where the machine is destroyed. It
	// physically doesn't exist anymore.
	Terminated

	// Snapshotting defines the state where the machine is in a snapshotting
	// process.
	Snapshotting

	// Pending defines the state where the machine is in a work-in-progress
	// state. A pending state might be a state between two stable states of a
	// machine such as Stopped and Starting where we resized a disk. A Machine
	// could be in a pending state when an ongoign maintenance is in progress.
	Pending
)

var States = map[string]State{
	"NotInitialized": NotInitialized,
	"Building":       Building,
	"Starting":       Starting,
	"Running":        Running,
	"Stopping":       Stopping,
	"Stopped":        Stopped,
	"Rebooting":      Rebooting,
	"Terminating":    Terminating,
	"Terminated":     Terminated,
	"Snapshotting":   Snapshotting,
	"Pending":        Pending,
	"Unknown":        Unknown,
	"":               Unknown,
}

// MarshalJSON implements the json.Marshaler interface. The state is a quoted
// string.
func (s State) MarshalJSON() ([]byte, error) {
	return []byte(`"` + s.String() + `"`), nil
}

// UnmarshalJSON implements the json.Unmarshaler interface. The state is
// expected to be a quoted string and available/exist in the States map.
func (s *State) UnmarshalJSON(d []byte) error {
	// comes as `"PENDING"`,  will convert to `PENDING`
	unquoted := strings.Replace(string(d), "\"", "", -1)

	var ok bool
	*s, ok = States[unquoted]
	if !ok {
		return fmt.Errorf("unknown value: %s", string(d))
	}
	return nil
}

// In checks if the state is available in the given state.
func (s State) In(states ...State) bool {
	for _, state := range states {
		if state == s {
			return true
		}
	}
	return false
}

// InProgress checks whether the given state is one of the states that defines
// a ongoing process, such as building, starting, stopping, etc...
func (s State) InProgress() bool {
	if s.In(Building, Starting, Stopping, Terminating, Rebooting, Pending) {
		return true
	}
	return false
}

// ValidMethods returns a list of valid methods which can be applied to the
// state that is not in progress. A method changes a machine states from one to
// another. For example a "Stopped" state will be changed to the final state
// "Running" when a "start" method is applied. However the final state can also
// be "Terminated" when a "destroy" method is applied. Thefore "start" and
// "destroy" both are valid methods for the state "Stopped" (so is "resize"
// too).
func (s State) ValidMethods() []string {
	// Nothing is valid for a state that is marked as "InProgress".
	if s.InProgress() {
		return nil
	}

	switch s {
	case NotInitialized:
		return []string{"build", "destroy"}
	case Running:
		return []string{
			"stop",
			"resize",
			"destroy",
			"restart",
			"reinit",
			"createSnapshot",
			"deleteSnapshot",
		}
	case Stopped:
		return []string{
			"start",
			"resize",
			"destroy",
			"reinit",
			"createSnapshot",
			"deleteSnapshot",
		}
	case Terminated:
		return []string{"build"}
	default:
		return nil
	}
}

func (s State) String() string {
	switch s {
	case NotInitialized:
		return "NotInitialized"
	case Building:
		return "Building"
	case Starting:
		return "Starting"
	case Running:
		return "Running"
	case Stopping:
		return "Stopping"
	case Stopped:
		return "Stopped"
	case Rebooting:
		return "Rebooting"
	case Terminating:
		return "Terminating"
	case Terminated:
		return "Terminated"
	case Snapshotting:
		return "Snapshotting"
	case Pending:
		return "Pending"
	case Unknown:
		fallthrough
	default:
		return "Unknown"
	}
}
