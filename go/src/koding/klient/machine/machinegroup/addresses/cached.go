package addresses

import (
	"sync"

	"koding/klient/machine"
	"koding/klient/storage"
)

// storageKey is a database key used to store machine addresses.
const storageKey = "addresses"

// Cached is an Addresses object with additional storage layer.
type Cached struct {
	mu sync.Mutex
	st storage.ValueInterface

	addresses *Addresses
}

// NewCached creates a new Cached object backed by provided storage.
func NewCached(st storage.ValueInterface) (*Cached, error) {
	c := &Cached{
		st:        st,
		addresses: New(),
	}

	if err := c.st.GetValue(storageKey, &c.addresses.m); err != nil {
		return nil, err
	}

	return c, nil
}

// Add adds provided address to a given machine and updates the cache.
func (c *Cached) Add(id machine.ID, addr machine.Addr) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if err := c.addresses.Add(id, addr); err != nil {
		return err
	}

	return c.st.SetValue(storageKey, c.addresses.all())
}

// Drop removes addresses which are binded to provided machine ID and updates
// the cache.
func (c *Cached) Drop(id machine.ID) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if err := c.addresses.Drop(id); err != nil {
		return err
	}

	return c.st.SetValue(storageKey, c.addresses.all())
}

// Latests returns the latest known address for a given machine and network.
func (c *Cached) Latest(id machine.ID, network string) (machine.Addr, error) {
	return c.addresses.Latest(id, network)
}

// MachineID checks if there is a machine ID that is binded to provided address
// If yes, the machine ID is returned. machine.ErrMachineNotFound is returned
// if there is no machine that has provided address.
func (c *Cached) MachineID(addr machine.Addr) (machine.ID, error) {
	return c.addresses.MachineID(addr)
}

// Registered returns all machines that are stored in this object.
func (c *Cached) Registered() []machine.ID {
	return c.addresses.Registered()
}
