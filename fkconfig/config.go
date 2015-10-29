package fkconfig

// Config contains user customizable options for mounting.
type Config struct {
	// IP is ip of user VM to connect.
	IP string `required:"true"`

	// RemotePath is path to folder in user VM to be mounted locally.
	RemotePath string `required:"true"`

	// LocalPath is path to folder in local to serve as mount point.
	LocalPath string `required:"true"`

	// MountName is identifier for the mounted folder.
	MountName string `default:"fuseklient"`

	// Debug determines if application debug logs are turned on.
	Debug bool `default:true`

	// FuseConfig determines if fuse library debug logs are turned on.
	FuseDebug bool `default:false`

	// IgnoreFolders are the folders for which all operations will return empty
	// response.
	IgnoreFolders []string
}
