package transport

import "os"

// Transport defines communication between this package and user VM.
type Transport interface {
	// CreateDir (recursively) creates dir with specified name and mode.
	CreateDir(string, os.FileMode) error

	// ReadDir returns entries of the dir at specified path. If specified it can
	// return nested entries of the dir in a flat data structure. The entries
	// are lexically ordered.
	ReadDir(string, bool) (*ReadDirRes, error)

	// Rename changes name of the entry from specified old to new name.
	Rename(string, string) error

	// Remove (recursively) removes the entries in the specified path.
	Remove(string) error

	// ReadFile reads file at specified path and return its contents.
	ReadFile(string) (*ReadFileRes, error)

	// ReadFileAt reads file at specified offset and path with specified block
	// size and returns it contents.
	ReadFileAt(string, int64, int64) (*ReadFileRes, error)

	// WriteFile writes file at specified path with data.
	WriteFile(string, []byte) error

	// Exec runs specified command. Note, it doesn't set the path from where it
	// executes the command.
	Exec(string) (*ExecRes, error)

	// GetDiskInfo returns disk info about the mount at the specified path. If a
	// nested path is specified, it returns the top most mount.
	GetDiskInfo(string) (*GetDiskInfoRes, error)

	// GetInfo returns info about the entry at specified path.
	GetInfo(string) (*GetInfoRes, error)

	// GetRemotePath is a helper method that returns the remote mounted path.
	GetRemotePath() string
}
