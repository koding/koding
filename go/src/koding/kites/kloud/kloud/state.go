package kloud

import "strings"

type MachineState int

const (
	// Machine instance does not exists
	NotInitialized MachineState = iota + 1
	Building                    // Build started machine instance creating...
	Starting                    // Machine is booting...
	Running                     // Machine is physically running
	Stopping                    // Machine is turning off...
	Stopped                     // Machine is turned off
	Rebooting                   // Machine is rebooting...
	Terminating                 // Machine is getting destroyed...
	Terminated                  // Machine is destroyed, not exists anymore
	Unknown                     // Unknown is a state that needs to be resolved manually
)

var states = map[string]MachineState{
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

func (m *MachineState) MarshalJSON() ([]byte, error) {
	return []byte(`"` + m.String() + `"`), nil
}

func (m *MachineState) UnmarshalJSON(d []byte) error {
	// comes as `"PENDING"`,  will convert to: `PENDING`
	unquoted := strings.Replace(string(d), "\"", "", -1)

	*m = states[unquoted]
	return nil
}

func (m MachineState) String() string {
	switch m {
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
