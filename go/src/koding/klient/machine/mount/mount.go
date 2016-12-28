package mount

// ID is a unique identifier of the mount.
type ID string

// Mount stores information about a single local to remote machine mount.
type Mount struct {
	Path  string `json:"path"`  // Mount point.
	RPath string `json:"rpath"` // Remote directory path.
}
