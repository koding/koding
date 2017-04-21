package addresses

import (
	"sync"
	"time"

	"koding/klient/machine"
)

// Addresses store addresses of all machines in the group.
type Addresses struct {
	mu sync.RWMutex
	m  map[machine.ID]*machine.AddrBook
}

// New creates an empty Addresses object.
func New() *Addresses {
	return &Addresses{
		m: make(map[machine.ID]*machine.AddrBook),
	}
}

// Add adds provided address to a given machine.
func (a *Addresses) Add(id machine.ID, addr machine.Addr) error {
	a.mu.Lock()
	defer a.mu.Unlock()

	ab, ok := a.m[id]
	if !ok {
		ab = &machine.AddrBook{
			MaxSize: 4, // maximum 4 records per address type.
		}
	}

	ab.Add(addr)
	a.m[id] = ab

	return nil
}

// Drop removes addresses which are binded to provided machine ID.
func (a *Addresses) Drop(id machine.ID) error {
	a.mu.Lock()
	defer a.mu.Unlock()
	delete(a.m, id)

	return nil
}

// Latest returns the latest known address for a given machine and network.
func (a *Addresses) Latest(id machine.ID, network string) (machine.Addr, error) {
	a.mu.RLock()
	defer a.mu.RUnlock()

	ab, ok := a.m[id]
	if !ok {
		return machine.Addr{}, machine.ErrMachineNotFound
	}

	return ab.Latest(network)
}

// MachineID checks if there is a machine ID that is binded to provided address
// If yes, the machine ID is returned. If there are more machines with the same
// address, machine with the newest address will be provided. ErrMachineNotFound
// is returned if there is no machine that has provided address.
func (a *Addresses) MachineID(addr machine.Addr) (machine.ID, error) {
	a.mu.RLock()
	defer a.mu.RUnlock()

	var (
		ret     machine.ID
		updated time.Time
	)

	for id, ab := range a.m {
		if u, err := ab.Updated(addr); err == nil && u.After(updated) {
			ret, updated = id, u
		}
	}

	if ret != "" {
		return ret, nil
	}

	return "", machine.ErrMachineNotFound
}

// Registered returns all machines that are stored in this object.
func (a *Addresses) Registered() machine.IDSlice {
	a.mu.RLock()
	defer a.mu.RUnlock()

	registered := make(machine.IDSlice, 0, len(a.m))
	for id := range a.m {
		registered = append(registered, id)
	}

	return registered
}

// all returns all stored address books.
func (a *Addresses) all() map[machine.ID]*machine.AddrBook {
	all := make(map[machine.ID]*machine.AddrBook)

	a.mu.RLock()
	defer a.mu.RUnlock()
	for id, addrbook := range a.m {
		// It is save to return pointer here since address book's internal
		// fields are synchronized internally.
		all[id] = addrbook
	}

	return all
}
