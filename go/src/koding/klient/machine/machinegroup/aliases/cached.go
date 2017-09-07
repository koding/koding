package aliases

import (
	"sync"

	"koding/klient/machine"
	"koding/klient/storage"
)

// storageKey is a database key used to store aliases.
const storageKey = "aliases"

// Cached is an Aliases object with additional storage layer.
type Cached struct {
	mu sync.Mutex
	st storage.ValueInterface

	aliases *Aliases
}

// NewCached creates a new Cached object backed by provided storage.
func NewCached(st storage.ValueInterface) (*Cached, error) {
	c := &Cached{
		st:      st,
		aliases: New(),
	}

	if err := c.st.GetValue(storageKey, &c.aliases.m); err != nil && err != storage.ErrKeyNotFound {
		return nil, err
	}

	// Drop inconsistent data.
	for id, alias := range c.aliases.m {
		if alias == "" {
			delete(c.aliases.m, id)
		}
	}

	return c, nil
}

// Add binds custom alias to provided machine and updates the cache.
func (c *Cached) Add(id machine.ID, alias string) error {
	return c.aliases.Add(id, alias)
}

// Create generates a new alias for provided machine ID and updates the cache.
// If alias already exists, it will not be regenerated nor cached.
func (c *Cached) Create(id machine.ID) (string, error) {
	return c.aliases.Create(id)
}

// Drop removes alias which is bound to provided machine ID and updates
// the cache.
func (c *Cached) Drop(id machine.ID) error {
	return c.aliases.Drop(id)
}

// MachineID checks if there is a machine ID that is bound to provided alias.
// If yes, the machine ID is returned. ErrAliasNotFound is be returned if there
// is no machine ID with provided alias.
func (c *Cached) MachineID(alias string) (machine.ID, error) {
	return c.aliases.MachineID(alias)
}

// Registered returns all machines that are stored in this object.
func (c *Cached) Registered() machine.IDSlice {
	return c.aliases.Registered()
}

// Cache saves aliases data to underlying storage.
func (c *Cached) Cache() error {
	c.mu.Lock()
	defer c.mu.Unlock()

	return c.st.SetValue(storageKey, c.aliases.all())
}
