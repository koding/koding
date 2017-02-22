package machine

import (
	"errors"
	"path"
	"time"

	"github.com/koding/logging"

	"koding/kites/tunnelproxy/discover"
	"koding/klient/fs"
	"koding/klient/kiteerrortypes"
	"koding/klient/os"
	"koding/klient/remote/kitepinger"
	"koding/klient/remote/rsync"
	"koding/klient/util"
	"sync"

	"github.com/koding/kite/dnode"
)

// MachineStatus represents our understanding of a machines status. Whether or not
// we can communicate with it, and etc.
type MachineStatus int

const (
	// Zero value, status is unknown
	MachineStatusUnknown MachineStatus = iota

	// The machine is not reachable for http
	MachineOffline

	// The machine & kite server are reachable via http
	MachineOnline

	// The machine has a kite and/or kitepinger trying to communicate with it,
	// but is failing.
	MachineDisconnected

	// The machine has an active and working kite connection.
	MachineConnected

	// The machine encountered an error
	MachineError

	// The machine is remounting
	//
	// TODO: Move this type to a mount specific status, once we support multiple
	// mounts.
	MachineRemounting
)

const (
	// The duration between IsConnected() checks performed by WaitUntilOnline()
	waitUntilOnlinePause = 5 * time.Second
)

var (
	// Returned by various methods if the requested machine cannot be found.
	ErrMachineNotFound error = util.KiteErrorf(
		kiteerrortypes.MachineNotFound, "Machine not found",
	)

	// Returned by various methods if the requested action is locked.
	ErrMachineActionIsLocked error = util.KiteErrorf(
		kiteerrortypes.MachineActionIsLocked, "Machine action is locked",
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
	// The kite url for the given machine.
	URL string `json:"url"`

	// The ip/host, as extracted from the client's URL field.
	IP string `json:"ip"`

	// The machine label, as seen on the Koding UI
	MachineLabel string `json:"machineLabel"`

	// The team name that the machine belongs to, if any.
	Teams []string `json:"teams"`

	// The human friendly name that is mainly used to locate the
	// given client.
	Name string `json:"name"`

	// The hostname of the remote machine.
	//
	// TODO: Deprecate once SSH no longer needs the remote hostname.
	Hostname string `json:"hostname"`

	// The username for the koding user.
	Username string `json:"username"`
}

// Machine represents a remote machine, with accompanying kite client and
// metadata.
type Machine struct {
	// The embedded static MachineMeta. Embedded, so we can save this struct
	// directly to the database.
	MachineMeta

	// The given machine status
	status MachineStatus `json:"-"`

	// The message (if any) associated with the given status.
	statusMessage string `json:"-"`

	// The underlying KitePinger which can be used to handle network interruptions
	// on the given machine.
	KiteTracker *kitepinger.PingTracker `json:"-"`

	// The underlying KiteHTTPPinger which can be used to know if the machine itself
	// is online (vs connected to)
	HTTPTracker *kitepinger.PingTracker `json:"-"`

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

	// Have we dialed the current transport, or not
	hasDialed bool

	// protects the hasDialed value.
	dialLock sync.Mutex

	// discover is used to query for SSH endpoint information of tunnelled
	// machines; it is also used to return local route if kd was invoked
	// from the same host as machine.
	discover *discover.Client

	// the mutexWithState values implement a locking mechanism for logical parts of
	// the Machine, such as mount actions - while also allowing the API caller to
	// check ahead of time if the action is locked. This enables Klient methods to
	// fail, rather than block, for long running processes.
	mountLocker *util.MutexWithState
}

// MachineLogger returns a new logger with the context of the given MachineMeta
func MachineLogger(meta MachineMeta, l logging.Logger) logging.Logger {
	return l.New("machine").New(
		"name", meta.Name,
		"ip", meta.IP,
	)
}

// NewMachine initializes a new Machine struct with any internal vars created.
func NewMachine(meta MachineMeta, log logging.Logger, t Transport) (*Machine, error) {
	log = MachineLogger(meta, log)

	// Create our Pingers, to be used in the PingTrackers
	kitePinger := kitepinger.NewKitePinger(t)
	httpPinger, err := kitepinger.NewKiteHTTPPinger(meta.URL)
	if err != nil {
		log.Error(
			"Unable to create HTTPPinger from meta.URL. url:%s, err:%s", meta.URL, err,
		)
		return nil, err
	}

	m := &Machine{
		MachineMeta: meta,
		Log:         log,
		KiteTracker: kitepinger.NewPingTracker(kitePinger),
		HTTPTracker: kitepinger.NewPingTracker(httpPinger),
		Transport:   t,
		discover:    discover.NewClient(),
		mountLocker: util.NewMutexWithState(),
	}

	m.discover.Log = m.Log.New("discover")

	// Start our http pinger, to give online/offline statuses for all machines.
	m.HTTPTracker.Start()

	return m, nil
}

// GetStatus returns the currently set machine status and status message, if any.
//
// This is safe to call for any Machine instance, valid or not.
func (m *Machine) GetStatus() (MachineStatus, string) {
	if m.status == MachineStatusUnknown {
		return m.getConnStatus(), ""
	}

	return m.GetRawStatus()
}

// GetRawStatus gets the plain status value, without checking any active statuses
// such as Connectivity.
func (m *Machine) GetRawStatus() (MachineStatus, string) {
	return m.status, m.statusMessage
}

// getConnStatus returns online/offline/connected/disconnected based on the
// given statuses.
//
// This is safe to call for any Machine instance, valid or not.
func (m *Machine) getConnStatus() MachineStatus {
	// Storing some vars for readability
	var (
		// If we have a kitepinger, and are actively pinging, we show
		// connected/disconnected
		useConnected bool

		// If we are not showing connected/disconnected, but we are pinging http,
		// use online/offline
		useOnline bool

		isConnected bool
		isOnline    bool
	)

	if m.KiteTracker != nil {
		useConnected = m.KiteTracker.IsPinging()
		isConnected = m.KiteTracker.IsConnected()
	}

	if m.HTTPTracker != nil {
		isOnline = m.HTTPTracker.IsPinging()
		useOnline = m.HTTPTracker.IsConnected()
	}

	switch {
	case useConnected && isConnected:
		return MachineConnected
	case useConnected && !isConnected:
		return MachineDisconnected
	case useOnline && isOnline:
		return MachineOnline
	default:
		return MachineOffline
	}
}

// SetStatus sets the machines status, along with an optional message.
func (m *Machine) SetStatus(s MachineStatus, msg string) {
	m.status = s
	m.statusMessage = msg
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
	if m.Transport == nil {
		return util.KiteErrorf(
			kiteerrortypes.MachineNotValidYet, "Machine.Transport is nil",
		)
	}

	if m.KiteTracker == nil {
		return util.KiteErrorf(
			kiteerrortypes.MachineNotValidYet, "Machine.KiteTracker is nil",
		)
	}

	if m.Log == nil {
		return util.KiteErrorf(kiteerrortypes.MachineNotValidYet, "Machine.Log is nil.")
	}

	return nil
}

// Dial dials the internal dialer.
func (m *Machine) Dial() (err error) {
	// set the resulting dial based on the success of the Dial method.
	// Note that repeated calls to Dial creates a new XHR transport, so failing
	// dial on an existing sets a new local client transport session.
	// In otherwords, a failed dial will result in a not-connected sessuin. Due to
	// this, we track the state of the dialed by result, regardless of original state.
	defer func() {
		m.hasDialed = err == nil
	}()

	if m.Transport == nil {
		m.Log.Error("Dial was attempted with a nil Transport")
		return util.KiteErrorf(
			kiteerrortypes.MachineNotValidYet, "Machine.Transport is nil",
		)
	}

	// Log the failure here, because this logger has machine context.
	if err := m.Transport.Dial(); err != nil {
		m.Log.Error("Dialer returned error. err:%s", err)
		return util.NewKiteError(kiteerrortypes.DialingFailed, err)
	}

	return nil
}

// DialOnce dials the machine once, and repeated dials do not trigger a dial.
func (m *Machine) DialOnce() error {
	m.dialLock.Lock()
	defer m.dialLock.Unlock()

	// If we've already dialed, don't dial again.
	if m.hasDialed {
		return nil
	}

	return m.Dial()
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

	if err := m.DialOnce(); err != nil {
		return nil, err
	}

	return m.Transport.Tell(method, args...)
}

// TellWithTimeout uses the Kite protocol (with a dnode response) to communicate
// with this machine.
func (m *Machine) TellWithTimeout(method string, timeout time.Duration, args ...interface{}) (*dnode.Partial, error) {
	if m.Transport == nil {
		m.Log.Error("TellWithTimeout was attempted with a nil Transport")
		return nil, util.KiteErrorf(
			kiteerrortypes.MachineNotValidYet, "Machine.Transport is nil",
		)
	}

	if err := m.DialOnce(); err != nil {
		return nil, err
	}

	return m.Transport.TellWithTimeout(method, timeout, args...)
}

// IsConnected returns the kitepinger's IsConnected result
func (m *Machine) IsConnected() bool {
	// If it's nil, this is a not a valid / connected machine.
	if m.KiteTracker == nil {
		return false
	}

	return m.KiteTracker.IsConnected()
}

// InitHTTPTracker creates the HTTPTracker for this Machine, if it is
// currently nil.
//
// This allows a caller to simply call this method beforehand on any machine,
// valid or not, and access the online/offline status of the remote kite.
func (m *Machine) InitHTTPTracker() error {
	if m.HasHTTPTracker() {
		return nil
	}

	// If the URL is empty, don't bother - nothing we can do.
	if m.URL == "" {
		return errors.New("Unable to Init HTTPTracker, Machine.URL is empty.")
	}

	httpPinger, err := kitepinger.NewKiteHTTPPinger(m.URL)
	if err != nil {
		return err
	}

	m.HTTPTracker = kitepinger.NewPingTracker(httpPinger)

	return nil
}

// IsOnline returns the httppingers IsConnected result.
func (m *Machine) IsOnline() bool {
	// If it's false, this is a not a valid / connected machine.
	if !m.HasHTTPTracker() {
		return false
	}

	return m.HTTPTracker.IsConnected()
}

// HasHTTPTracker returns whether or not the machine has an HTTPTracker, and thusly
// cannot properly know if the machine is online or not.
//
// An example use case being, machine.IsOnline() could return false but if there
// is no HTTPTracker, it cannot actually know if the machine is offline. Checking
// if the machine has an HTTPTracker would help ensure that the machine is indeed
// offline.
func (m *Machine) HasHTTPTracker() bool {
	return m.HTTPTracker != nil
}

// ConnectedAt returns the kitepinger's ConnectedAt result
func (m *Machine) ConnectedAt() time.Time {
	// If it's nil, this is a not a valid / connected machine.
	if m.KiteTracker == nil {
		return time.Time{} // Zero value time.
	}

	return m.KiteTracker.ConnectedAt()
}

// OnlineAt returns the httppingers's ConnectedAt result
func (m *Machine) OnlineAt() time.Time {
	// If it's nil, this is a not a valid / connected machine.
	if m.HTTPTracker == nil {
		return time.Time{} // Zero value time.
	}

	return m.HTTPTracker.ConnectedAt()
}

// WaitUntilOnline returns a channel allowing the caller to be notified once
// the Machine is online.
func (m *Machine) WaitUntilOnline() <-chan struct{} {
	c := make(chan struct{})
	go func() {
		for !m.IsOnline() {
			time.Sleep(waitUntilOnlinePause)
		}

		// Notify the caller that the we're connected
		c <- struct{}{}
		close(c)
		return
	}()
	return c
}

// IsMountingLocked returns whether or not mount actions (unmount included) are
// locked for this machine. Allowing the caller to fail instead of blocking for
// an unknown period of time.
func (m *Machine) IsMountingLocked() bool {
	return m.mountLocker.IsLocked()
}

// LockMounting locks Mount related actions with this machine.
func (m *Machine) LockMounting() {
	m.mountLocker.Lock()
}

// UnlockMounting locks Mount related actions with this machine.
func (m *Machine) UnlockMounting() {
	m.mountLocker.Unlock()
}

// DoesRemotePathExist checks if the given remote dir exists for this
// machine.
func (m *Machine) DoesRemoteDirExist(p string) (bool, error) {
	opts := fs.GetInfoOptions{
		Path: p,
	}

	kRes, err := m.TellWithTimeout("fs.getInfo", 4*time.Second, opts)
	if err != nil {
		return false, err
	}

	var f fs.FileEntry
	if err := kRes.Unmarshal(&f); err != nil {
		return false, err
	}

	return f.Exists && f.IsDir, nil
}

func (m *Machine) GetFolderSize(p string) (int64, error) {
	opts := fs.GetFolderSizeOptions{
		Path: p,
	}

	kRes, err := m.TellWithTimeout("fs.getPathSize", 4*time.Second, opts)
	if err != nil {
		return 0, err
	}

	var size int64
	if err := kRes.Unmarshal(&size); err != nil {
		return 0, err
	}

	return size, nil
}

// Home attempts to return the home directory of the remote machine.
func (m *Machine) Home() (string, error) {
	u := m.Username
	if u == "" {
		return "", errors.New("Machine username is missing, unable to find Home.")
	}

	opts := os.HomeOptions{
		Username: u,
	}

	// First try to get the real home
	res, err := m.TellWithTimeout("os.home", 4*time.Second, opts)
	if err != nil {
		return "", err
	}

	var home string
	if err := res.Unmarshal(&home); err != nil {
		return "", err
	}

	return home, nil
}

// HomeWithDefault attempts to get the home value, but defaults if it cannot
// get the system users true home.
//
// The remote system being unable to find the users home is most commonly due to
// running an older klient.
func (m *Machine) HomeWithDefault() (string, error) {
	home, err := m.Home()
	if err == nil {
		return home, nil
	}

	// If home fails, it might be due to a missing transport. Assume log is missing
	// too (ie, not valid machine) to prevent a panic.
	if m.Log != nil {
		m.Log.New("homeWithDefault").Warning(
			"Failed to get real Home value. Ignoring error. err:%s",
			err,
		)
	}

	u := m.Username
	if u == "" {
		return "", errors.New("Unable to find home directory")
	}

	// TODO: Add a system identifier (ie, runtime.GOOS for the remote system), and
	// with that system identifier we can provide sane defaults with the username.
	//
	// Ie, OSX is /Users/u, linux is /home/u, etc. Not 100%, but in the event of a
	// fallback it's better than just assuming/home.
	return path.Join("/home", u), nil
}

// DoesRemotePathExist checks if the given remote path exists for this
// machine.
func (m *Machine) DoesRemotePathExist(p string) (bool, error) {
	opts := fs.GetInfoOptions{
		Path: p,
	}

	kRes, err := m.TellWithTimeout("fs.getInfo", 4*time.Second, opts)
	if err != nil {
		return false, err
	}

	var f fs.FileEntry
	if err := kRes.Unmarshal(&f); err != nil {
		return false, err
	}

	return f.Exists, nil
}

func (ms MachineStatus) String() string {
	switch ms {
	case MachineStatusUnknown:
		return "MachineStatusUnknown"
	case MachineOffline:
		return "MachineOffline"
	case MachineOnline:
		return "MachineOnline"
	case MachineDisconnected:
		return "MachineDisconnected"
	case MachineConnected:
		return "MachineConnected"
	case MachineError:
		return "MachineError"
	case MachineRemounting:
		return "MachineRemounting"
	default:
		return "UnknownMachineConstant"
	}
}
