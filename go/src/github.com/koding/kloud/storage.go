package kloud

import (
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
)

// TODO split it into Lock and Storage (asignee should be seperated)
type Storage interface {
	// Get returns the machine data associated with the given id from the
	// username
	Get(id, username string) (*protocol.Machine, error)

	// Update updates the fields in the data for the given id
	Update(id string, data *StorageData) error

	// UpdateState updates the machine state for the given machine id
	UpdateState(id string, state machinestate.State) error

	// ResetAssignee resets the assigne which was acquired with Get()
	ResetAssignee(id string) error

	// Assignee returns the unique identifier that is responsible of doing the
	// actions of this interface.
	Assignee() string
}

type StorageData struct {
	Type string
	Data map[string]interface{}
}
