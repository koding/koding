package kloud

import "github.com/koding/kloud/machinestate"

// TODO split it into Lock and Storage (asignee should be seperated)
type Storage interface {
	// Get returns the machine data associated with the given id
	Get(id string) (*Machine, error)

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

type Machine struct {
	// Provider defines the provider in which the data is used be
	Provider string

	// Data contains the necessary information to build/start a machine. For
	// example to creat a DigitalOcean machine, it would contain region_id,
	// image_id,etc.. For a EC2 machine it would contain a instance_type,
	// ami_id, etc..
	Data map[string]interface{}

	// Credential contains the necessary information to successfull
	// authenticate with the third party provider. Every provider has his own
	// access, secret, token keys ..
	Credential map[string]interface{}

	// State defines the machines current state
	State machinestate.State
}
