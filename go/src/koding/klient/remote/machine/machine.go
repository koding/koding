package machine

import (
	"errors"
	"fmt"

	"github.com/koding/kite"
	"github.com/koding/logging"

	"koding/klient/kiteerrortypes"
	"koding/klient/remote/kitepinger"
	"koding/klient/remote/rsync"
	"koding/klient/util"

	"github.com/koding/kite/dnode"
)

var (
	// Returned by various methods if the requested machine cannot be found.
	ErrMachineNotFound error = util.KiteErrorf(
		kiteerrortypes.MachineNotFound, "Machine not found",
	)
)

// MachineMeta is used to separate the static data from the Machine constructor
// fields. Easing creation.
type MachineMeta struct {
	// The machine label, as seen on the Koding UI
	MachineLabel string

	// The team name that the machine belongs to, if any.
	Teams []string

	// The ip/host, as extracted from the client's URL field.
	IP string

	// The human friendly name that is mainly used to locate the
	// given client.
	Name string
}

// Machine represents a remote machine, with accompanying kite client and
// metadata.
type Machine struct {
	// The embedded static MachineMeta. Embedded, so we can save this struct
	// directly to the database.
	MachineMeta

	// A remote client, as returned by `kontrolclient.GetKites()`
	//
	// TODO: Deprecated. Remove when able.
	Client *kite.Client

	// The kitePinger which can be used to handle network interruptions
	// on the given machine.
	KitePinger kitepinger.KitePinger

	// The intervaler for this machine.
	//
	// TODO: In the future this needs to be a manager which associates folders to the
	// given intervaler. For now however, we only support a single mount per-machine,
	// so it's unneeded.
	Intervaler rsync.SyncIntervaler

	// The Logger for this Machine instance.
	Log logging.Logger

	// The interfaces below this are mainly used for Mocking.

	// Dialer is the interface that Machine.Dial() uses to dial. Normally
	// kite.Client is used to satisfy this interface.
	Dialer interface {
		Dial() error
	}

	// Teller is an interface that Machine.Dial, Machine.Tell, and any method that
	// communicates with the remote kite uses.
	Teller interface {
		Tell(string, ...interface{}) (*dnode.Partial, error)
	}
}

// NewMachine initializes a new Machine struct with any internal vars created.
func NewMachine(meta MachineMeta, log logging.Logger, client *kite.Client,
	pinger kitepinger.KitePinger) *Machine {
	log = log.New(
		"machine",
		fmt.Sprintf("name=%s", meta.Name),
		fmt.Sprintf("ip=%s", meta.IP),
	)

	return &Machine{
		// Client is mainly a legacy field. See field docs.
		Client: client,

		MachineMeta: meta,
		Log:         log,
		KitePinger:  pinger,
		Dialer:      client,
		Teller:      client,
	}
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

	return nil, ErrMachineNotFound
}

// GetByName iterates through the Machine names and returns the first matching
// machine.
func (machines Machines) GetByName(n string) (*Machine, error) {
	for _, m := range machines {
		if m.Name == n {
			return m, nil
		}
	}

	return nil, ErrMachineNotFound
}

// Dial dials the internal dialer.
func (m *Machine) Dial() error {
	if m.Dialer == nil {
		m.Log.Error("Unable to dial. Nil Dialer")
		return errors.New("Unable to dial, Machine Dialer is nil")
	}

	err := m.Dialer.Dial()

	// Log the failure here, because this logger has machine context.
	if err != nil {
		m.Log.Error("Dialer returned error. err:%s", err)
	}

	return err
}

// Tell uses the Kite protocol (with a dnode response) to communicate with this
// machine.
func (m *Machine) Tell(method string, args ...interface{}) (*dnode.Partial, error) {
	return m.Teller.Tell(method, args...)
}

// Ping is a convenience method for pinging the given machine. An easy way to
// determine a valid connection.
func (m *Machine) Ping() error {
	_, err := m.Tell("kite.ping")
	return err
}
