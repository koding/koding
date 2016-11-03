package machine

import (
	"errors"

	"koding/db/mongodb/modelhelper"
)

type MongoDatabase struct{}

// Machines returns all machines stored in MongDB database that matches a given
// filter.
func (m *MongoDatabase) Machines(f *Filter) ([]*Machine, error) {
	if f == nil {
		return nil, errors.New("machine filter is not set")
	}

	if f.Username == "" {
		return nil, errors.New("machine filter: user name is required")
	}

	machinesDB, err := modelhelper.GetMachinesByUsername(f.Username)
	if err != nil {
		return nil, err
	}

	machines := make([]*Machine, len(machinesDB))
	for i := range machinesDB {
		machines[i] = &Machine{
			Team:     "TODO",
			IP:       machinesDB[i].IpAddress,
			Provider: machinesDB[i].Provider,
			Label:    machinesDB[i].Label,
			Status: MachineStatus{
				State:      machinesDB[i].Status.State,
				Reason:     machinesDB[i].Status.Reason,
				ModifiedAt: machinesDB[i].Status.ModifiedAt,
			},
		}
	}

	return machines, nil
}
