package mounts

import (
	"koding/klient/machine"
	"koding/klient/machine/mount"
)

// Mounter is an interface used to manage machines' mounts.
type Mounter interface {
	// Add adds provided mount to a given machine.
	Add(machine.ID, mount.ID, mount.Mount) error

	// Remove removes a given mount from cache.
	Remove(mount.ID) error

	// Drop removes all mounts which are binded to provided machine ID.
	Drop(machine.ID) error

	// Path returns mount ID which mount's local path is equal to provided
	// argument.
	Path(string) (mount.ID, error)

	// RemotePath returns all mount IDs which RemotePath field matches provided
	// argument.
	RemotePath(string) (mount.IDSlice, error)

	// MachineID gets machine ID based on provided mount ID.
	MachineID(mount.ID) (machine.ID, error)

	// All returns a copy of all mounts connected with a given machine.
	All(machine.ID) (map[mount.ID]mount.Mount, error)

	// Registered returns all machines that are managed by mounter.
	Registered() machine.IDSlice
}
