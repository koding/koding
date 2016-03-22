package restypes

import "koding/klient/remote/machine"

// ListMachineInfo is the machine info response from the `remote.list` handler.
type ListMachineInfo struct {
	// The machines last known status.
	MachineStatus machine.MachineStatus `json:"machineStatus"`

	// The message (if any) associated with the machine status.
	StatusMessage string `json:"statusMessage"`

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

	// Used by kd ssh to determine ssh user
	Hostname string `json:"hostname"`

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
	Username    string
}

// ListMountInfo is the machine info response from the `remote.list` handler.
type ListMountInfo struct {
	RemotePath     string `json:"remotePath"`
	LocalPath      string `json:"localPath"`
	LastMountError bool   `json:"lastMountError"`
}
