package kloud

type MachineState int

const (
	NotInitialized MachineState = iota + 1 // Machine instance does not exists
	Building                               // Build started machine instance creating...
	Starting                               // Machine is booting...
	Running                                // Machine is physically running
	Stopping                               // Machine is turning off...
	Stopped                                // Machine is turned off
	Rebooting                              // Machine is rebooting...
	Terminating                            // Machine is getting destroyed...
	Terminated                             // Machine is destroyed, not exists anymore
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
	default:
		return "UnknownState"
	}
}
