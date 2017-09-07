package metadata

import "koding/klient/machine"

// Entry stores additional information about single machine.
type Entry struct {
	Owner string `json:"owner"`
	Label string `json:"label"`
}

// Metadater is an interface used to manage machines' metadata.
type Metadater interface {
	// Add binds custom alias to provided machine.
	Add(machine.ID, *machine.Metadata) error

	// Drop removes machine metadata.
	Drop(machine.ID) error

	// MachineID looks up machine ID based on provided owner and machine label.
	// It may return more than one ID if there are machines with identical
	// labels across different stacks.
	MachineID(owner, label string) (machine.IDSlice, error)

	// Registered returns all machines that are managed by metadater.
	Registered() machine.IDSlice
}
