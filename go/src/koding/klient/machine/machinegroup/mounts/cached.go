package mounts

import (
	"sync"

	"koding/klient/machine"
	"koding/klient/machine/mount"
	"koding/klient/storage"
)

// storageKey is a database key used to store mounts.
const storageKey = "mounts"

// Cached is a Mounts object with additional storage layer.
type Cached struct {
	mu sync.Mutex
	st storage.ValueInterface

	mounts *Mounts
}

// NewCached creates a new Cached object backed by provided storage.
func NewCached(st storage.ValueInterface) (*Cached, error) {
	c := &Cached{
		st:     st,
		mounts: New(),
	}

	if err := c.st.GetValue(storageKey, &c.mounts.m); err != nil && err != storage.ErrKeyNotFound {
		return nil, err
	}

	// Drop inconsistent data.
	for id, mb := range c.mounts.m {
		if mb == nil {
			delete(c.mounts.m, id)
		}
	}

	return c, nil
}

// Add adds provided mount to a given machine and updates the cache.
func (c *Cached) Add(id machine.ID, mountID mount.ID, m mount.Mount) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if err := c.mounts.Add(id, mountID, m); err != nil {
		return err
	}

	return c.st.SetValue(storageKey, c.mounts.all())
}

// Remove removes a given mount from cache ad updates it.
func (c *Cached) Remove(mountID mount.ID) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if err := c.mounts.Remove(mountID); err != nil {
		return err
	}

	return c.st.SetValue(storageKey, c.mounts.all())
}

// Drop removes all mounts which are binded to provided machine ID and
// updates the cache.
func (c *Cached) Drop(id machine.ID) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if err := c.mounts.Drop(id); err != nil {
		return err
	}

	return c.st.SetValue(storageKey, c.mounts.all())
}

// Path returns mount ID which mount's local path is equal to provided
// argument.
func (c *Cached) Path(path string) (mount.ID, error) {
	return c.mounts.Path(path)
}

// RemotePath returns all mount IDs which RemotePath field matches provided
// argument.
func (c *Cached) RemotePath(path string) (mount.IDSlice, error) {
	return c.mounts.RemotePath(path)
}

// MachineID gets machine ID based on provided mount ID.
func (c *Cached) MachineID(mountID mount.ID) (machine.ID, error) {
	return c.mounts.MachineID(mountID)
}

// All returns a copy of all mounts connected with a given machine.
func (c *Cached) All(id machine.ID) (map[mount.ID]mount.Mount, error) {
	return c.mounts.All(id)
}

// Registered returns all machines that are managed by mounter.
func (c *Cached) Registered() machine.IDSlice {
	return c.mounts.Registered()
}
