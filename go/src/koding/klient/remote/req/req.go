package req

import (
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
	Debug          bool   `json:"debug"`
	Name           string `json:"name"`
	LocalPath      string `json:"localPath"`
	RemotePath     string `json:"remotePath"`
	NoIgnore       bool   `json:"noIgnore"`
	NoPrefetchMeta bool   `json:"noPrefetchMeta"`
	PrefetchAll    bool   `json:"prefetchAll"`
	NoWatch        bool   `json:"noWatch"`
	CachePath      string `json:"cachePath"`
	Trace          bool   `json:"trace"`
	SyncMount      bool   `json:"syncMount"`
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
	Name string
	Key  []byte
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
