package kloud

import (
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
)

type Storage interface {
	// Create creates a new machine data for the given username with the
	// default values. It returns the ID of the machine data so the following
	// methods can be used to manage the data.
	Create(username string) (string, error)

	// Get returns the machine data associated with the given id from the
	// username
	Get(id string) (*protocol.Machine, error)

	// Delete delets the machine data associated with the given id
	Delete(id string) error

	// Update updates the fields in the data for the given id
	Update(id string, data *StorageData) error

	// UpdateState updates the machine state for the given machine id with the
	// given reason
	UpdateState(id, reason string, state machinestate.State) error
}

type StorageData struct {
	Type string
	Data map[string]interface{}
}
