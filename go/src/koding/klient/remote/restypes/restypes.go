package restypes

// ListMachineInfo is the machine info response from the `remote.list` handler.
type ListMachineInfo struct {
	// Whether or not a kite pinger is actively pinging (and most recently succeeding)
	// this machine.
	Connected bool

	// The Ip of the running machine
	IP string

	// The human friendly "name" of the machine.
	VMName string

	// The machine label, as seen by the koding ui
	MachineLabel string

	// The team names for the remote machine, if any
	Teams []string

	Mounts []ListMountInfo

	// TODO DEPRECATE
	MountedPaths []string

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
	Hostname    string
	Username    string
}

// ListMountInfo is the machine info response from the `remote.list` handler.
type ListMountInfo struct {
	RemotePath string `json:"remotePath"`
	LocalPath  string `json:"localPath"`
}
