package machine

import (
	"encoding/json"
	"fmt"
	"koding/klient/storage"

	"github.com/koding/logging"
)

const (
	// The key used to store machines in the database, allowing machine / machinemeta
	// to persist between Klient restarts.
	machinesStorageKey = "machines"
)

// 15 names to be used to identify machines.
var sourceMachineNames = []string{
	"apple", "orange", "banana", "grape", "coconut", "peach", "mango", "date",
	"kiwi", "lemon", "squash", "jackfruit", "raisin", "tomato", "quince",
}

// Machines is responsible for storing and querying the *Machine(s)
type Machines struct {
	Log logging.Logger

	// The internal list of mounts
	machines []*Machine

	// A storage interface to store mount information
	storage storage.Interface
}

func NewMachines(log logging.Logger, s storage.Interface) *Machines {
	return &Machines{
		Log:     log.New("Machines"),
		storage: s,
	}
}

// Add adds the given machine to this Machines struct.
func (ms *Machines) Add(m *Machine) error {
	if m.Name == "" {
		m.Name = ms.CreateUniqueName()
		ms.Log.Debug("Created name for new Machine. name:%s", m.Name)
	}

	ms.machines = append(ms.machines, m)
	return nil
}

// Remove removes the given machine from this Machines struct.
//
// It does *not* save the resulting machines to the database. This must be done
// manually by calling Machines.Save()
func (ms *Machines) Remove(m *Machine) error {
	var (
		found bool
		i     int
		mach  *Machine
	)

	// Iterate through the machines, to find the index we want to remove
	for i, mach = range ms.machines {
		if mach == m {
			found = true
			break
		}
	}

	// If it's not found, there's nothing we need to do.
	if !found {
		return ErrMachineNotFound
	}

	ms.machines = append(ms.machines[:i], ms.machines[i+1:]...)
	return nil
}

// Count simply returns the total machines under this struct.
func (ms *Machines) Count() int {
	return len(ms.machines)
}

// GetByIP iterates through the Machines, returning the first one with a
// matching IP.
func (machines *Machines) GetByIP(i string) (*Machine, error) {
	for _, m := range machines.machines {
		if m.IP == i {
			return m, nil
		}
	}

	return nil, ErrMachineNotFound
}

// GetByName iterates through the Machine names and returns the first matching
// machine.
func (machines *Machines) GetByName(n string) (*Machine, error) {
	for _, m := range machines.machines {
		if m.Name == n {
			return m, nil
		}
	}

	return nil, ErrMachineNotFound
}

// Machines returns a slice of *Machine found i this struct.
func (ms *Machines) Machines() []*Machine {
	return ms.machines[:]
}

// CreateUniqueName returns a potential machine name which is generated from
// the default names list, and is not taken by any existing machines in this
// Machines struct.
func (ms *Machines) CreateUniqueName() string {
	// For ease of looking up, new ip names, we need to map existing
	// names to their respective ips, since they are stored in the
	// reverse.
	takenNames := map[string]struct{}{}
	for _, machine := range ms.machines {
		takenNames[machine.Name] = struct{}{}
	}

	for mod := 0; ; mod++ {
		for _, name := range sourceMachineNames {
			// Don't append an integer if it's mod zero
			if mod != 0 {
				name = fmt.Sprintf("%s%d", name, mod)
			}
			if _, ok := takenNames[name]; !ok {
				return name
			}
		}
	}
}

// Load the machines from storage into this struct. This *replaces* any
// existing machines.
func (ms *Machines) Load() error {
	ms.Log.Debug("Loading machines from db. current machine count:%d", ms.Count())

	// TODO: Figure out how to filter the "key not found error", so that
	// we don't ignore all errors.
	data, err := ms.storage.Get(machinesStorageKey)
	if err != nil {
	}

	// If there is no data, we have nothing to load.
	if data == "" {
		return nil
	}

	if err := json.Unmarshal([]byte(data), &ms.machines); err != nil {
		return err
	}

	// Add what instances we can to the loaded machines, such as loggers.
	for _, m := range ms.machines {
		m.Log = MachineLogger(m.MachineMeta, ms.Log)
	}

	return nil
}

// Save the current machines to the local storage.
func (ms *Machines) Save() error {
	ms.Log.Debug("Saving machines to db. totalMachines:%d", ms.Count())

	data, err := json.Marshal(ms.machines)
	if err != nil {
		return err
	}

	if err = ms.storage.Set(machinesStorageKey, string(data)); err != nil {
		return err
	}

	return nil
}
