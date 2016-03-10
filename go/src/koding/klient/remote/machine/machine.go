package machine

import (
	"errors"
	"time"

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

// Transport is a Kite compatible interface for Machines.
type Transport interface {
	Dial() error
	Tell(string, ...interface{}) (*dnode.Partial, error)
	TellWithTimeout(string, time.Duration, ...interface{}) (*dnode.Partial, error)
}

// MachineMeta is used to separate the static data from the Machine constructor
// fields. Easing creation.
type MachineMeta struct {
	// The machine label, as seen on the Koding UI
	MachineLabel string `json:"machineLabel"`

	// The team name that the machine belongs to, if any.
	Teams []string `json:"teams"`

	// The ip/host, as extracted from the client's URL field.
	IP string `json:"ip"`

	// The human friendly name that is mainly used to locate the
	// given client.
	Name string `json:"name"`
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
	Client *kite.Client `json:"-"`

	// The kitePinger which can be used to handle network interruptions
	// on the given machine.
	KitePinger kitepinger.KitePinger `json:"-"`

	// The intervaler for this machine.
	//
	// TODO: In the future this needs to be a manager which associates folders to the
	// given intervaler. For now however, we only support a single mount per-machine,
	// so it's unneeded.
	Intervaler rsync.SyncIntervaler `json:"-"`

	// The Logger for this Machine instance.
	Log logging.Logger `json:"-"`

	// Transport is an interface that Machine.Dial, Machine.Tell, and any method that
	// communicates with the remote kite uses.
	Transport Transport `json:"-"`
}

func MachineLogger(meta MachineMeta, l logging.Logger) logging.Logger {
	return l.New("machine").New(
		"name", meta.Name,
		"ip", meta.IP,
	)
}

// NewMachine initializes a new Machine struct with any internal vars created.
func NewMachine(meta MachineMeta, log logging.Logger, client *kite.Client,
	pinger kitepinger.KitePinger) *Machine {
	return &Machine{
		// Client is mainly a legacy field. See field docs.
		Client: client,

		MachineMeta: meta,
		Log:         MachineLogger(meta, log),
		KitePinger:  pinger,
		Transport:   client,
	}
}

// Dial dials the internal dialer.
func (m *Machine) Dial() error {
	if m.Transport == nil {
		m.Log.Error("Unable to dial. Nil Transport")
		return errors.New("Unable to dial, Machine Transport is nil")
	}

	err := m.Transport.Dial()

	// Log the failure here, because this logger has machine context.
	if err != nil {
		m.Log.Error("Dialer returned error. err:%s", err)
	}

	return err
}

// Tell uses the Kite protocol (with a dnode response) to communicate with this
// machine.
func (m *Machine) Tell(method string, args ...interface{}) (*dnode.Partial, error) {
	return m.Transport.Tell(method, args...)
}

// Ping is a convenience method for pinging the given machine. An easy way to
// determine a valid connection.
func (m *Machine) Ping() error {
	_, err := m.Tell("kite.ping")
	return err
}
