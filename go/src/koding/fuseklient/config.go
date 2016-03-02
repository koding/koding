package fuseklient

// Config contains user customizable options for mounting.
type Config struct {
	// Path is path to folder in local to serve as mount point.
	Path string `required:"true"`

	// MountName is identifier for the mounted folder.
	MountName string `default:"fuseklient"`

	// Debug determines if application debug logs are turned on.
	Debug bool `default:true`

	// NoIgnore determines whether to ignore default or user specified folders.
	// Use this to turn off default ignoring of folders.
	NoIgnore bool `default:false`

	// NoPrefetchMeta determines if we should fetch metadata on mount time. This
	// makes mounts slightly slower, however it speeds up regular read directory
	// a LOT. It fetches metadata recursively directories, but not contents of
	// the files.
	NoPrefetchMeta bool `default:false`

	// NoWatch determines if we should watch for remote file changes and send
	// them to local. Without this any changes that happen on remote won't be
	// visible after mount.
	NoWatch bool `default:false`
}
