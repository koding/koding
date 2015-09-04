package main

// FuseConfig contains user specificable variables.
type FuseConfig struct {
	// KlientIP is the ip of VM to connect.
	KlientIP string `required:"true"`

	// ExternalPath is path of folder in user VM to be mounted locally.
	ExternalPath string `required:"true"`

	// InternalPath is path of folder in local to serve as mount point.
	InternalPath string `required:"true"`

	// MountName is identifier for mount.
	MountName string `default:"fuseklient"`

	// Debug determines if debug logs should be shown to user.
	Debug bool `default:false`

	// SshUser is the optional ssh username to use when running
	// install-alpha.sh and gaining klient credentials. Whether or not this
	// is required.
	SshUser string
}
