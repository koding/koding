package kloud

import (
	"fmt"

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

	// Assignee returns the unique identifier that is responsible of doing the
	// actions of this interface.
	Assignee() string
}

type StorageData struct {
	Type string
	Data map[string]interface{}
}

// TODO: after changing our errors variable change it to errors.New()
var ErrLockAcquired = fmt.Errorf("lock is already acquired by someone else")

// Locker is a distributed lock that locks with the specific id and undlocks
// again with the given id.
type Locker interface {
	// Lock should lock with the given Id. If there is a lock already it should
	// return the ErrLockAcquired error.
	Lock(id string) error

	// Unlock unlocks the lock with the given id.
	Unlock(id string)
}
