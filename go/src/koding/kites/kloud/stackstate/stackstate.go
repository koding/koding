// Package stackstate defines the lifecycle of a stack with states.
package stackstate

import (
	"fmt"
	"strings"
)

// State defines the stack state
type State int

const (
	// Unknown is a state that needs to be resolved manually
	Unknown State = iota

	// NotInitialzed defines a state where the stack does not exists and was
	// not built . It's waits to be initialized.
	NotInitialized

	// Initialized defines the state where the stack is built and in a functional state
	Initialized

	// Destroying is in progress of destroying the stack.
	Destroying

	// Building is in progress of creating the stack. A successful building
	// state results in an Initialized state.
	Building
)

var States = map[string]State{
	"NotInitialized": NotInitialized,
	"Initialized":    Initialized,
	"Building":       Building,
	"Destroying":     Destroying,
	"Unknown":        Unknown,
}

// MarshalJSON implements the json.Marshaler interface. The state is a quoted
// string.
func (s State) MarshalJSON() ([]byte, error) {
	return []byte(`"` + s.String() + `"`), nil
}

// UnmarshalJSON implements the json.Unmarshaler interface. The state is
// expected to be a quoted string and available/exist in the States map.
func (s *State) UnmarshalJSON(d []byte) error {
	// comes as `"BUILDING"`,  will convert to `BUILDING`
	unquoted := strings.Replace(string(d), "\"", "", -1)

	var ok bool
	*s, ok = States[unquoted]
	if !ok {
		return fmt.Errorf("unknown value: %s", string(d))
	}
	return nil
}

// InProgress checks whether the given state is one of the states that defines
// a ongoing process, such as building, destroying, etc...
func (s State) InProgress() bool {
	if s.In(Building, Destroying) {
		return true
	}
	return false
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

func (s State) String() string {
	switch s {
	case NotInitialized:
		return "NotInitialized"
	case Initialized:
		return "Initialized"
	case Building:
		return "Building"
	case Destroying:
		return "Destroying"
	case Unknown:
		fallthrough
	default:
		return "Unknown"
	}
}
