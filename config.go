package main

// FuseConfig contains user specificable variables.
type FuseConfig struct {
	// IP is ip of VM to connect.
	IP string `required:"true"`

	// RemotePath is path to folder in user VM to be mounted locally.
	RemotePath string `required:"true"`

	// LocalPath is path to folder in local to serve as mount point.
	LocalPath string `required:"true"`

	// MountName is identifier for mount.
	MountName string `default:"fuseklient"`

	// SshUser is the optional ssh username for user in `install-alpha.sh`.
	// TODO: remove this after intergrating with Klient.
	SshUser string
}
