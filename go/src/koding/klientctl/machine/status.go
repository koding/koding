package machine

// Status represents our understanding of a machines status. Whether or not we
// can communicate with it, and etc.
type Status int

const (
	// Zero value, status is unknown.
	StatusUnknown MachineStatus = iota

	// The machine is not reachable via HTTP protocol.
	StatusOffline

	// The machine & kite server are reachable via HTTP protocol.
	StatusOnline

	// The machine has a kite and/or kitepinger is trying to communicate with
	// it, but is failing.
	StatusDisconnected

	// The machine has an active and working kite connection.
	StatusConnected

	// The machine encountered an error
	StatusError

	// The machine is remounting
	//
	// TODO: Move this type to a mount specific status, once we support multiple
	// mounts.
	StatusRemounting
)

// String implements
func (s Status) String() string {
	switch s {
	case StatusUnknown:
		return "unknown"
	case StatusOffline:
		return "offline"
	case StatusOnline:
		return "online"
	case StatusDisconnected:
		return "disconnected"
	case StatusConnected:
		return "connected"
	case StatusError:
		return "error"
	case StatusRemounting:
		return "remounting"
	default:
		return "<invalid value>"
	}
}
