package addresses

import "koding/klient/machine"

// Addresser is an interface used to manage machines' network addresses.
type Addresser interface {
	// Add adds provided address to a given machine.
	//
	// TODO(ppknap): make this function variadic.
	Add(machine.ID, machine.Addr) error

	// Drop removes addresses which are binded to provided machine ID.
	Drop(machine.ID) error

	// Latests returns the latest known address for a given machine and network.
	Latest(machine.ID, string) (machine.Addr, error)

	// MachineID gets machine ID based on provided address.
	MachineID(machine.Addr) (machine.ID, error)

	// Registered returns all machines that are managed by addresser.
	Registered() machine.IDSlice
}
