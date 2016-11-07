package machine

import (
	"koding/kites/kloud/machinestate"
)

// State represents our understanding of a machines state. Whether or not we
// can communicate with it, and etc.
type State int

const (
	// Zero value, state is unknown.
	StateUnknown State = iota

	// The machine is not reachable via HTTP protocol.
	StateOffline

	// The machine & kite server are reachable via HTTP protocol.
	StateOnline

	// The machine has a kite and/or kitepinger is trying to communicate with
	// it, but is failing.
	StateDisconnected

	// The machine has an active and working kite connection.
	StateConnected

	// The machine encountered an error
	StateError

	// The machine is remounting
	//
	// TODO: Move this type to a mount specific state, once we support multiple
	// mounts.
	StateRemounting
)

// String implements fmt.Stringer interface and is used for pretty-printing
// machine state.
func (s State) String() string {
	switch s {
	case StateUnknown:
		return "unknown"
	case StateOffline:
		return "offline"
	case StateOnline:
		return "online"
	case StateDisconnected:
		return "disconnected"
	case StateConnected:
		return "connected"
	case StateError:
		return "error"
	case StateRemounting:
		return "remounting"
	default:
		return "<invalid value>"
	}
}

// ms2State maps machinestate states to State objects.
var ms2State = map[machinestate.State]State{
	machinestate.NotInitialized: StateOffline,
	machinestate.Building:       StateOffline,
	machinestate.Starting:       StateOffline,
	machinestate.Running:        StateOnline,
	machinestate.Stopping:       StateOffline,
	machinestate.Stopped:        StateOffline,
	machinestate.Rebooting:      StateOffline,
	machinestate.Terminating:    StateOffline,
	machinestate.Terminated:     StateOffline,
	machinestate.Snapshotting:   StateOffline,
	machinestate.Pending:        StateOffline,
	machinestate.Unknown:        StateUnknown,
}

// FromMachineStateString converts machinestate string to State object.
func fromMachineStateString(raw string) State {
	return ms2State[machinestate.States[raw]]
}
