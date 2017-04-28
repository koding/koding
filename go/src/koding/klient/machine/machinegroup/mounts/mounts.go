package mounts

import (
	"fmt"
	"path/filepath"
	"strings"
	"sync"

	"koding/klient/machine"
	"koding/klient/machine/mount"
)

// Mounts store mounts of all machines in the group.
type Mounts struct {
	mu sync.RWMutex
	m  map[machine.ID]*mount.MountBook
}

// New creates an empty Mounts object.
func New() *Mounts {
	return &Mounts{
		m: make(map[machine.ID]*mount.MountBook),
	}
}

// Add adds provided mount to a given machine.
func (ms *Mounts) Add(id machine.ID, mountID mount.ID, m mount.Mount) error {
	ms.mu.Lock()
	defer ms.mu.Unlock()

	// Check if mount with given ID already exist.
	if _, err := ms.machineID(mountID); err == nil {
		return fmt.Errorf("mount with ID %s already exists", mountID)
	}

	// Check if mount to local directory already exist.
	if exMountID, err := ms.path(m.Path); err == nil {
		return fmt.Errorf("local directory is already used by mount %s", exMountID)
	} else if err != mount.ErrMountNotFound {
		return err
	}

	// Check if remote directory of given machine is already mounted.
	if mids, err := ms.remotePath(id, m.RemotePath); err != mount.ErrMountNotFound {
		if len(mids) == 0 {
			panic("found non existing mounts")
		}

		return fmt.Errorf("remote directory is already mounted in %s", strings.Join(mids.StringSlice(), ", "))
	}

	mb, ok := ms.m[id]
	if !ok {
		mb = mount.NewMountBook()
	}

	mb.Add(mountID, m)
	ms.m[id] = mb

	return nil
}

// Remove removes a given mount from the cache.
func (ms *Mounts) Remove(mountID mount.ID) error {
	ms.mu.Lock()
	defer ms.mu.Unlock()

	for id, mb := range ms.m {
		all := mb.All()
		switch _, ok := all[mountID]; {
		case ok && len(all) == 1:
			// Drop the entire mount book.
			delete(ms.m, id)
			return nil
		case ok:
			mb.Remove(mountID)
			return nil
		}
	}

	return nil
}

// Drop removes all mounts which are binded to provided machine ID.
func (ms *Mounts) Drop(id machine.ID) error {
	ms.mu.Lock()
	defer ms.mu.Unlock()
	delete(ms.m, id)

	return nil
}

// Path returns mount ID which mount's local path is equal to provided
// argument. Path must be absolute and cleaned. mount.ErrMountNotFound is
// returned if there is no mount with provided ID.
func (ms *Mounts) Path(path string) (mount.ID, error) {
	ms.mu.RLock()
	defer ms.mu.RUnlock()

	return ms.path(path)
}

func (ms *Mounts) path(path string) (mount.ID, error) {
	if !filepath.IsAbs(path) {
		return "", fmt.Errorf("path %q is not absolute", path)
	}

	for _, mb := range ms.m {
		if mountID, err := mb.Path(path); err == nil {
			return mountID, nil
		}
	}

	return "", mount.ErrMountNotFound
}

// RemotePath returns all mount IDs which RemotePath field matches provided
// argument. mount.ErrMountNotFound is returned if there is no mount with
// provided ID.
func (ms *Mounts) RemotePath(path string) (ids mount.IDSlice, err error) {
	ms.mu.RLock()
	defer ms.mu.RUnlock()

	return ms.remotePath("", path)
}

func (ms *Mounts) remotePath(id machine.ID, path string) (ids mount.IDSlice, err error) {
	for machineID, mb := range ms.m {
		if id != "" && id != machineID {
			continue
		}

		if mids, err := mb.RemotePath(path); err == nil {
			ids = append(ids, mids...)
		}
	}

	if len(ids) == 0 {
		return nil, mount.ErrMountNotFound
	}

	return ids, nil
}

// MachineID gets machine ID based on provided mount ID. mount.ErrMountNotFound
// is returned if there is no mount with provided ID.
func (ms *Mounts) MachineID(mountID mount.ID) (machine.ID, error) {
	ms.mu.RLock()
	defer ms.mu.RUnlock()

	return ms.machineID(mountID)
}

func (ms *Mounts) machineID(mountID mount.ID) (machine.ID, error) {
	for id, mb := range ms.m {
		for storedID := range mb.All() {
			if mountID == storedID {
				return id, nil
			}
		}
	}

	return "", mount.ErrMountNotFound
}

// All returns a copy of all mounts connected with a given machine.
func (ms *Mounts) All(id machine.ID) (map[mount.ID]mount.Mount, error) {
	ms.mu.RLock()
	defer ms.mu.RUnlock()

	if mb, ok := ms.m[id]; ok {
		return mb.All(), nil
	}

	return nil, machine.ErrMachineNotFound
}

// Registered returns all machines that are managed by mounts object.
func (ms *Mounts) Registered() machine.IDSlice {
	ms.mu.RLock()
	defer ms.mu.RUnlock()

	registered := make(machine.IDSlice, 0, len(ms.m))
	for id := range ms.m {
		registered = append(registered, id)
	}

	return registered
}

// all returns all stored mounts.
func (ms *Mounts) all() map[machine.ID]*mount.MountBook {
	all := make(map[machine.ID]*mount.MountBook)

	ms.mu.RLock()
	defer ms.mu.RUnlock()
	for id, mb := range ms.m {
		// It is save to return pointer here since mount book's internal
		// fields are synchronized internally.
		all[id] = mb
	}

	return all
}
