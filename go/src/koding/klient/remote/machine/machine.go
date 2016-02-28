package machine

import (
	"fmt"

	"github.com/koding/kite"

	"koding/klient/remote/kitepinger"
	"koding/klient/remote/rsync"
)

// Machine represents a remote machine, with accompanying kite client and
// metadata.
type Machine struct {
	// A remote client, as returned by `kontrolclient.GetKites()`
	Client *kite.Client

	// The kitePinger which can be used to handle network interruptions
	// on the given machine.
	KitePinger kitepinger.KitePinger

	// The machine label, as seen on the Koding UI
	MachineLabel string

	// The team name that the machine belongs to, if any.
	Teams []string

	// The ip/host, as extracted from the client's URL field.
	IP string

	// The human friendly name that is mainly used to locate the
	// given client.
	Name string

	// The intervaler for this machine.
	//
	// TODO: In the future this needs to be a manager which associates folders to the
	// given intervaler. For now however, we only support a single mount per-machine,
	// so it's unneeded.
	Intervaler rsync.SyncIntervaler
}

// NewMachine initializes a new Machine struct with any internal vars created.
func NewMachine() *Machine {
	return &Machine{}
}

// Machines is responsible for storing the *Machine(s) and providing
// them in query-able forms.
//
// For now this is just a slice of *Machine, but in time it will likely
// become a struct with more features, performant querying, etc.
type Machines []*Machine

// GetByIP iterates through the Machines, returning the first one with a
// matching IP.
func (machines Machines) GetByIP(i string) (*Machine, error) {
	for _, m := range machines {
		if m.IP == i {
			return m, nil
		}
	}

	return nil, fmt.Errorf("No machine found with specified ip: `%s`", i)
}

// GetByName iterates through the Machine names and returns the first matching
// machine.
func (machines Machines) GetByName(n string) (*Machine, error) {
	for _, m := range machines {
		if m.Name == n {
			return m, nil
		}
	}

	return nil, fmt.Errorf("No machine found with specified name: `%s`", n)
}
