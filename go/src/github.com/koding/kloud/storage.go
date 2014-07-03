package kloud

import (
	"github.com/koding/kloud/machinestate"

	"labix.org/v2/mgo/bson"
)

type Storage interface {
	// Get returns to MachineData
	Get(string, *GetOption) (*MachineData, error)

	// Update updates the fields in the data for the given id
	Update(string, *StorageData) error

	// UpdateState updates the machine state for the given machine id
	UpdateState(string, machinestate.State) error

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

// GetOption defines which parts should be included into MachineData, used for
// optimizing the the performance for certain lookups.
type GetOption struct {
	IncludeMachine    bool
	IncludeCredential bool
	IncludeStack      bool
}

type MachineData struct {
	Provider   string
	Machine    *Machine
	Credential *Credential
	Stack      *Stack
}

type Credential struct {
	Id        bson.ObjectId `bson:"_id" json:"-"`
	PublicKey string        `bson:"publicKey"`
	Meta      bson.M        `bson:"meta"`
}

type Stack struct {
	Id bson.ObjectId `bson:"_id" json:"-"`
}
