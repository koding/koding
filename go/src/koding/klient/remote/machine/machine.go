package machine

import (
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

// MachineLogger returns a new logger with the context of the given MachineMeta
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

// CheckValid checks if this Machine is missing any required fields. Fields can be
// missing because we store all machines, online or offline, but Kontrol doesn't
// return any information about offline machines. We don't have Kites, for offline
// machines. Because of this, a Machine may exist, but not be usable.
//
// Eg, you could attempt to mount an offline machine - if it hasn't connected
// to kontrol since klient restarted, it won't be valid.
//
// This is a common check, and should be performed before using a machine.
func (m *Machine) CheckValid() error {
	if m.Log == nil {
		return util.KiteErrorf(kiteerrortypes.MachineNotValidYet, "Machine.Log is nil.")
	}

	if m.Client == nil {
		return util.KiteErrorf(kiteerrortypes.MachineNotValidYet, "Machine.Client is nil")
	}

	if m.Client == nil {
		return util.KiteErrorf(
			kiteerrortypes.MachineNotValidYet, "Machine.KitePinger is nil",
		)
	}

	if m.Transport == nil {
		return util.KiteErrorf(
			kiteerrortypes.MachineNotValidYet, "Machine.Transport is nil",
		)
	}

	return nil
}

// Dial dials the internal dialer.
func (m *Machine) Dial() error {
	if m.Transport == nil {
		m.Log.Error("Dial was attempted with a nil Transport")
		return util.KiteErrorf(
			kiteerrortypes.MachineNotValidYet, "Machine.Transport is nil",
		)
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
	if m.Transport == nil {
		m.Log.Error("Tell was attempted with a nil Transport")
		return nil, util.KiteErrorf(
			kiteerrortypes.MachineNotValidYet, "Machine.Transport is nil",
		)
	}

	return m.Transport.Tell(method, args...)
}

// Ping is a convenience method for pinging the given machine. An easy way to
// determine a valid connection.
func (m *Machine) Ping() error {
	_, err := m.Tell("kite.ping")
	return err
}

// IsConnected returns the kitepinger's IsConnected result
func (m *Machine) IsConnected() bool {
	// If it's nil, this is a not a valid / connected machine.
	if m.KitePinger == nil {
		return false
	}

	return m.KitePinger.IsConnected()
}

// ConnectedAt returns the kitepinger's ConnectedAt result
func (m *Machine) ConnectedAt() time.Time {
	// If it's nil, this is a not a valid / connected machine.
	if m.KitePinger == nil {
		return time.Time{} // Zero value time.
	}

	return m.KitePinger.ConnectedAt()
}
