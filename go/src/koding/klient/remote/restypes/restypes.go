package restypes

import (
	"koding/klient/remote/machine"
	"time"
)

// ListMachineInfo is the machine info response from the `remote.list` handler.
type ListMachineInfo struct {
	// The machines last known status.
	MachineStatus machine.MachineStatus `json:"machineStatus"`

	// The message (if any) associated with the machine status.
	StatusMessage string `json:"statusMessage"`

	// The last time this machine was online. This may be zero valued if this machine
	// has not been online since Klient was restarted.
	OnlineAt time.Time `json:"onlineAt"`

	// The Ip of the running machine
	IP string `json:"ip"`

	// The human friendly "name" of the machine.
	VMName string `json:"vmName"`

	// The machine label, as seen by the koding ui
	MachineLabel string `json:"machineLabel"`

	// The team names for the remote machine, if any
	Teams []string `json:"teams"`

	Mounts []ListMountInfo `json:"mounts"`

	// The username of the koding user.
	Username string

	// TODO DEPRECATE
	MountedPaths []string `json:"mountedPaths"`

	// Used by kd ssh to determine ssh user
	//
	// TODO: Deprecate once ssh no longer needs this.
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
}

// ListMountInfo is the machine info response from the `remote.list` handler.
type ListMountInfo struct {
	MountName  string `json:"mountName"`
	RemotePath string `json:"remotePath"`
	LocalPath  string `json:"localPath"`
	MountType  int    `json:"mountType"`
}
