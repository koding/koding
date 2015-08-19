package kodingutils

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo/bson"
)

// IsKodingOwnedVM return if VM is owned by Koding.
func IsKodingOwnedVM(id bson.ObjectId) (bool, error) {
	machine, err := modelhelper.GetMachine(id)
	if err != nil {
		return false, err
	}

	return machine.Provider == models.MachineKodingProvider, nil
}
