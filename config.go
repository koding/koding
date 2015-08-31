package main

// FuseConfig contains user specificable variables.
type FuseConfig struct {
	// KlientIP is the ip of VM to connect.
	KlientIP string

	// ExternalPath is path of folder in user VM to be mounted locally.
	ExternalPath string

	// InternalPath is path of folder in local to serve as mount point.
	InternalPath string
}
