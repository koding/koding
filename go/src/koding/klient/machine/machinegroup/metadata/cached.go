package metadata

import (
	"sync"

	"koding/klient/machine"
	"koding/klient/storage"
)

// storageKey is a database key used to store metadata.
const storageKey = "metadata"

// Cached is an Metadata object with additional storage layer.
type Cached struct {
	mu sync.Mutex
	st storage.ValueInterface

	metadata *Metadata
}

// NewCached creates a new Cached object backed by provided storage.
func NewCached(st storage.ValueInterface) (*Cached, error) {
	c := &Cached{
		st:       st,
		metadata: New(),
	}

	if err := c.st.GetValue(storageKey, &c.metadata.m); err != nil && err != storage.ErrKeyNotFound {
		return nil, err
	}

	// Drop inconsistent data.
	empty := machine.Metadata{}
	for id, meta := range c.metadata.m {
		if meta == nil || *meta == empty {
			delete(c.metadata.m, id)
		}
	}

	return c, nil
}

// Add binds metadata to provided machine.
func (c *Cached) Add(id machine.ID, meta *machine.Metadata) error {
	return c.metadata.Add(id, meta)
}

// Get gets metadata for provided machine.
func (c *Cached) Get(id machine.ID) (*machine.Metadata, error) {
	return c.metadata.Get(id)
}

// Drop removes metadata bound to provided machine ID.
func (c *Cached) Drop(id machine.ID) error {
	return c.metadata.Drop(id)
}

// MachineID checks if there is a machine ID that which has provided label and
// belongs to provided owner.
func (c *Cached) MachineID(owner, label string) (machine.IDSlice, error) {
	return c.metadata.MachineID(owner, label)
}

// Registered returns all machines that are stored in this object.
func (c *Cached) Registered() machine.IDSlice {
	return c.metadata.Registered()
}

// Cache saves aliases data to underlying storage.
func (c *Cached) Cache() error {
	c.mu.Lock()
	defer c.mu.Unlock()

	return c.st.SetValue(storageKey, c.metadata.all())
}
