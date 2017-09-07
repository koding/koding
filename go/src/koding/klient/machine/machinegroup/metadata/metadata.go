package metadata

import (
	"errors"
	"sync"

	"koding/klient/machine"
)

// Metadata stores metadata of a group of unique machines.
type Metadata struct {
	mu sync.RWMutex
	m  map[machine.ID]*Entry
}

// New creates an empty Metadata object.
func New() *Metadata {
	return &Metadata{
		m: make(map[machine.ID]*Entry),
	}
}

// Add binds metadata to provided machine.
func (m *Metadata) Add(id machine.ID, entry *Entry) error {
	if entry == nil {
		return errors.New("nil metadata is not allowed")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	m.m[id] = entry

	return nil
}

// Drop removes metadata entry bound to provided machine ID.
func (m *Metadata) Drop(id machine.ID) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	delete(m.m, id)

	return nil
}

// MachineID checks if there is a machine ID that which has provided label and
// belongs to provided owner. Owner for current user should be empty. If there
// is no machines with provided data, machine.ErrMachineNotFound is returned.
func (m *Metadata) MachineID(owner, label string) (machine.IDSlice, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	ids := make(machine.IDSlice, 0)
	for id, entry := range m.m {
		if entry == nil {
			continue
		}

		if entry.Owner == owner && entry.Label == label {
			ids = append(ids, id)
		}
	}

	if len(ids) == 0 {
		return nil, machine.ErrMachineNotFound
	}

	ids.Sort()
	return ids, nil
}

// Registered returns all machines that are stored in this object.
func (m *Metadata) Registered() machine.IDSlice {
	m.mu.RLock()
	defer m.mu.RUnlock()

	registered := make(machine.IDSlice, 0, len(m.m))
	for id := range m.m {
		registered = append(registered, id)
	}

	return registered
}

// all returns all stored entry objects.
func (m *Metadata) all() map[machine.ID]*Entry {
	all := make(map[machine.ID]*Entry)

	m.mu.RLock()
	defer m.mu.RUnlock()

	for id, entry := range m.m {
		all[id] = entry
	}

	return all
}
