package config

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

	// IgnoreFolders are the remote folders which will be ignored, ie not
	// downloaded or be available for folder operations. Use this to ignore
	// folders like .git, logs/, bin/ etc.
	IgnoreFolders []string

	// NoIgnore determines whether to ignore default or user specified folders.
	// Use this to turn off default ignoring of folders.
	NoIgnore bool `default:false`

	// Prefetch determines if we should fetch metadata on mount time. This makes
	// mounts slightly slower, however it speeds up regular read directory a LOT.
	// It fetches metadata recursively directories, but not contents of files.
	Prefetch bool `default:true`
}
