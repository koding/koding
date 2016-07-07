package req

import (
	"koding/klient/fs"
	"koding/klient/remote/rsync"
	"time"
)

type StatusItem int

const (
	UnknownStatus StatusItem = iota
	KontrolStatus
	MachineStatus
)

// MountFolder is the request struct for remote.mountFolder method.
type MountFolder struct {
	Debug           bool   `json:"debug"`
	Name            string `json:"name"`
	LocalPath       string `json:"localPath"`
	RemotePath      string `json:"remotePath"`
	NoIgnore        bool   `json:"noIgnore"`
	NoPrefetchMeta  bool   `json:"noPrefetchMeta"`
	PrefetchAll     bool   `json:"prefetchAll"`
	NoWatch         bool   `json:"noWatch"`
	CachePath       string `json:"cachePath"`
	Trace           bool   `json:"trace"`
	OneWaySyncMount bool   `json:"oneWaySyncMount"`
}

// UnmountFolder is the request struct for remote.UnmountFolder method.
type UnmountFolder struct {
	Name      string `json:"name"`
	LocalPath string `json:"localPath"`
}

// Exec is the request struct for remote.exec method.
type Exec struct {
	// TODO: Standardize this field name among all remote* methods.
	Machine string
	Command string
	Path    string
}

// SSHAuthSock is the request struct for remote.sshKeysAdd method.
type SSHKeyAdd struct {
	Debug bool

	// The MachineName to add to.
	Name string

	// The key being added.
	Key []byte

	// The username to add the key to, on the remote machine.
	Username string
}

// Cache is the request struct for remote.cache method.
type Cache struct {
	// Log debug info for this request.
	Debug bool `json:"debug"`

	Name       string        `json:"name"`
	LocalPath  string        `json:"localPath"`
	RemotePath string        `json:"remotePath"`
	Interval   time.Duration `json:"interval"`

	// OnlyInterval will not perform any type of cache request immediately, and
	// instead only start the intervaler.
	OnlyInterval bool

	// LocalToRemote indicates that this cache request will copy local to remote. If
	// false, Remote is copied to Local.
	LocalToRemote bool `json:"localToRemote"`

	// Implementation details required by rsync currently. Not great to expose the
	// underlying implementation, but required currently.

	// The username of ssh user to connect to.
	Username string `json:"username"`

	// The SSH_AUTH_SOCK to set as an Environment variable when calling RSync.
	// Because RSync is being run from Klient, Klient may not have the SSH_AUTH_SOCK
	// var set for the calling user. This results in SSH failing.
	SSHAuthSock string `json:"sshAuthSock"`

	// The keypath that SSH will use for rsync.
	SSHPrivateKeyPath string `json:"sshPrivateKeyPath"`

	// IgnoreFile is the full path to CVS ignore file for rsync.
	IgnoreFile string `json:"ignoreFile"`

	// IncludeFolder includes the folder in the destination, otherwise it just
	// includes the contents.
	//
	// This must be true for copying files, or the remote will attempt to copy
	// `your/path/` (a directory) instead of `your/path` (a directory, *or file*)
	IncludePath bool `json:"includePath"`
}

type Status struct {
	// Item is the name of the thing you want
	Item StatusItem `json:"item"`

	// MachineName is the machine name to query the status of.
	MachineName string `json:"machineName"`
}

type MountInfo struct {
	// MountName is the mount name to get info on.
	MountName string `json:"mountName"`
}

type MountInfoResponse struct {
	// Embedded mountfolder fields
	MountFolder

	// Used for prefetch / cache.
	SyncIntervalOpts rsync.SyncIntervalOpts
}

// Remount is the struct for klient's remote.remount method.
type Remount struct {
	MountName string `json:"mountName"`
}

type ReadDirectoryOptions struct {
	// The embedded ReadDirectoryOptions
	fs.ReadDirectoryOptions

	// The machine name to run the ReadDirectory on.
	Machine string
}

// CurrentUsernameOptions
type CurrentUsernameOptions struct {
	Debug bool

	// The MachineName to add to.
	MachineName string
}

func (i StatusItem) String() string {
	switch i {
	case KontrolStatus:
		return "KontrolStatus"
	case MachineStatus:
		return "MachineStatus"
	default:
		return "UnknownStatus"
	}
}
