// Package machinestate defines the lifecycle of a machine with states.
package machinestate

import "strings"

// State defines the Machines state
type State int

const (
	// NotInitialzed defines a state where the machine instance does not exists
	// and was not built once. It's waits to be initialized
	NotInitialized State = iota + 1

	// Building is in progress of creating the machine A successfull Booting
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

	// Unknown is a state that needs to be resolved manually
	Unknown
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
	"Unknown":        Unknown,
}

// MarshalJSON implements the json.Marshaler interface. The state is a quoted
// string.
func (s *State) MarshalJSON() ([]byte, error) {
	return []byte(`"` + s.String() + `"`), nil
}

// UnmarshalJSON implements the json.Unmarshaler interface. The state is
// expected to be a quoted string and available/exist in the States map.
func (s *State) UnmarshalJSON(d []byte) error {
	// comes as `"PENDING"`,  will convert to: `PENDING`
	unquoted := strings.Replace(string(d), "\"", "", -1)

	*s = States[unquoted]
	return nil
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
	case Unknown:
		return "Unknown"
	default:
		return "UnknownState"
	}
}
