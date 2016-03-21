package restypes

// ListMachineInfo is the machine info response from the `remote.list` handler.
type ListMachineInfo struct {
	// Whether or not a kite pinger is actively pinging (and most recently succeeding)
	// this machine.
	MachineStatus MachineStatus `json:"machineStatus"`

	// The Ip of the running machine
	IP string `json:"ip"`

	// The human friendly "name" of the machine.
	VMName string `json:"vmName"`

	// The machine label, as seen by the koding ui
	MachineLabel string `json:"machineLabel"`

	// The team names for the remote machine, if any
	Teams []string `json:"teams"`

	Mounts []ListMountInfo `json:"mounts"`

	// TODO DEPRECATE
	MountedPaths []string `json:"mountedPaths"`

	// Kite identifying values. For reference, see:
	// https://github.com/koding/kite/blob/master/protocol/protocol.go#L18
	//
	// TODO DEPRECATED: Values are left here to satisfy response types, but are
	// not populated in the response from `remote.list`.
	Name        string
	ID          string
	Environment string
	Region      string
	Version     string
	Hostname    string `json:"hostname"`
	Username    string
}

// ListMountInfo is the machine info response from the `remote.list` handler.
type ListMountInfo struct {
	RemotePath     string `json:"remotePath"`
	LocalPath      string `json:"localPath"`
	LastMountError bool   `json:"lastMountError"`
}

// MachineStatus representes our understanding of a machines status. Whether or not
// we can communicate with it, and etc.
type MachineStatus int

const (
	// The machine is not reachable for http
	MachineOffline MachineStatus = iota

	// The machine & kite server are reachable via http
	MachineOnline

	// The machine has a kite and/or kitepinger trying to communicate with it,
	// but is failing.
	MachineDisconnected

	// The machine has an active and working kite connection.
	MachineConnected
)

func (ms MachineStatus) String() string {
	switch ms {
	case MachineOffline:
		return "MachineOffline"
	case MachineOnline:
		return "MachineOnline"
	case MachineDisconnected:
		return "MachineDisconnected"
	case MachineConnected:
		return "MachineConnected"
	default:
		return "UnknownMachineConstant"
	}
}
