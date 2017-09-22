package aliases

import "koding/klient/machine"

// Aliaser is an interface used to manage machines' alternative names.
type Aliaser interface {
	// Add binds custom alias to provided machine.
	Add(machine.ID, string) error

	// Create generates a new alias for provided machine ID.
	Create(machine.ID) (string, error)

	// Drop removes alias which is bound to provided machine ID.
	Drop(machine.ID) error

	// MachineID gets machine ID from provided alias.
	MachineID(string) (machine.ID, error)

	// Registered returns all machines that are managed by aliaser.
	Registered() machine.IDSlice
}
