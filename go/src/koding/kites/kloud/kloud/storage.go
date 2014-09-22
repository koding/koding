package kloud

import (
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
)

type Storage interface {
	// Get returns the machine data associated with the given id from the
	// username
	Get(id string) (*protocol.Machine, error)

	// Update updates the fields in the data for the given id
	Update(id string, data *StorageData) error

	// UpdateState updates the machine state for the given machine id
	UpdateState(id string, state machinestate.State) error
}

type StorageData struct {
	Type string
	Data map[string]interface{}
}
