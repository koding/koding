package kloud

import (
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
)

type Storage interface {
	// Get returns the machine data associated with the given id from the
	// username
	Get(id string) (*protocol.Machine, error)

	// Delete delets the machine data associated with the given id
	Delete(id string) error

	// Update updates the fields in the data for the given id
	Update(id string, data *StorageData) error

	// UpdateState updates the machine state for the given machine id
	UpdateState(id string, state machinestate.State) error
}

type StorageData struct {
	Type string
	Data map[string]interface{}
}

type DomainStorage interface {
	// Add adds a new domain
	Add(*protocol.Domain) error

	// Delete deletes the DomainDocument with the given domain name
	Delete(name string) error

	// UpdateMachine updates the machine relationship for the given domain name
	// with the given new machine id. Machine ID can be empty
	UpdateMachine(name, machine string) error

	// Get returns the domain information with the given domain name
	Get(name string) (*protocol.Domain, error)
}
