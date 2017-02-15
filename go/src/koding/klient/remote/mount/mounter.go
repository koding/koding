package mount

import (
	"errors"
	"koding/fuseklient"
	"koding/fuseklient/transport"
	"koding/klient/kiteerrortypes"
	"koding/klient/remote/kitepinger"
	"koding/klient/remote/machine"
	"koding/klient/remote/req"
	"koding/klient/remote/rsync"
	"koding/klient/util"
	"time"

	"github.com/jacobsa/fuse"
	"golang.org/x/net/context"

	"github.com/koding/kite/dnode"
	"github.com/koding/logging"
)

// EventType represents a single mounting/unmounting event type.
//
// When mounter transitions state of the mount it emits two events
// - one describing beginning of the operation, second describing
// its result.
//
// On successful mount operation the following events are emitted:
//
//  1) Event{Path: "/path", Type: EventMounting, Err: nil}
//  2) Event{Path: "/path", Type: EventMounted, Err: nil}
//
// And on unsuccessful mount operation:
//
//  1) Event{Path: "/path", Type: EventMounting, Err: nil}
//  2) Event{Path: "/path", Type: EventMounting, Err: errDescribing}
//
type EventType uint8

const (
	EventUnknown EventType = iota + 1
	EventMounting
	EventMounted
	EventUnmounting
	EventUnmounted
)

// Event represents a single mounting/unmounting event.
type Event struct {
	Path string
	Type EventType
	Err  error
}

const (
	// fuseTellTimout is the timeout that all kite method calls over the network
	// will take to timeout. This should be large enough as to allow large files to
	// be send over the kite callback protocol, but also small enough to allow the
	// network error to be presented to the user in the event of network disruptions.
	//
	// If left too large, the Kernel (in OSX, for example) will fail fs ops by printing
	// "Socket is not connected" to the user. So if that message is seen, this value
	// likely needs to be lowered.
	fuseTellTimeout = 55 * time.Second
)

var (
	// ErrRemotePathDoesNotExist is returned when the remote path does not exist,
	// or is not a dir.
	ErrRemotePathDoesNotExist = util.KiteErrorf(
		kiteerrortypes.RemotePathDoesNotExist,
		"The RemotePath either does not exist, or is not a dir",
	)
)

// MounterTransport is the transport that the Mounter uses to communicate with
// the remote machine.
type MounterTransport interface {
	Tell(string, ...interface{}) (*dnode.Partial, error)
	TellWithTimeout(string, time.Duration, ...interface{}) (*dnode.Partial, error)
}

// Mounter is responsible for actually mounting fuse mounts from Klient.
type Mounter struct {
	Log logging.Logger

	// The options for this Mounter, such as LocalFolder, etc.
	Options req.MountFolder

	// The machine we'll be mounting to.
	Machine *machine.Machine

	// The IP of the remote machine.
	IP string

	// The KiteTracker that the remote machine this Mounter uses, will deal with.
	KiteTracker *kitepinger.PingTracker

	// The intervaler for this machine.
	//
	// TODO: In the future this needs to be a manager which associates folders to the
	// given intervaler. For now however, we only support a single mount per-machine,
	// so it's unneeded.
	Intervaler rsync.SyncIntervaler

	// The transport we will use to mount with.
	Transport MounterTransport

	// MountAdder stores the new mount in storage, memory, and anywhere else needed.
	MountAdder interface {
		AddMount(*Mount) error
	}

	// PathUnmounter is responsible for unmounting the given path. Usually implemented
	// by fuseklient.Unmount(path)
	PathUnmounter func(string) error

	// EventSub receives events when paths get mounted / unmounted.
	EventSub chan<- *Event
}

// IsConfigured checks the Mounter fields to ensure (as best as it can) that
// there are no missing required fields, such as mock fields and etc.
func (m *Mounter) IsConfigured() error {
	if m.Options.Name == "" {
		return util.KiteErrorf(kiteerrortypes.MissingArgument, "Missing Name")
	}

	if m.Options.LocalPath == "" {
		return util.KiteErrorf(kiteerrortypes.MissingArgument, "Missing LocalPath")
	}

	if m.IP == "" {
		return util.KiteErrorf(kiteerrortypes.MissingArgument, "Missing IP")
	}

	if m.Options.PrefetchAll && m.Options.CachePath == "" {
		return util.KiteErrorf(kiteerrortypes.MissingArgument,
			"Using PrefetchAll but missing CachePath")
	}

	if m.Machine == nil {
		return util.KiteErrorf(kiteerrortypes.MissingArgument, "Missing Machine")
	}

	if m.KiteTracker == nil {
		return util.KiteErrorf(kiteerrortypes.MissingArgument, "Missing KiteTracker")
	}

	if m.Transport == nil {
		return util.KiteErrorf(kiteerrortypes.MissingArgument, "Missing Transport")
	}

	if m.PathUnmounter == nil {
		return util.KiteErrorf(kiteerrortypes.MissingArgument, "Missing Unmounter")
	}

	if m.Log == nil {
		return util.KiteErrorf(kiteerrortypes.MissingArgument, "Missing Log")
	}

	return nil
}

func (m *Mounter) IsMountPathTaken() error {
	return errors.New("Not implemented")
}

func (m *Mounter) Mount() (*Mount, error) {
	if err := m.IsConfigured(); err != nil {
		m.Log.Error("Mounter improperly configured. err:%s", err)
		return nil, err
	}

	// Mount() requires a MountAdder
	if m.MountAdder == nil {
		return nil, util.KiteErrorf(kiteerrortypes.MissingArgument, "Missing MountAdder")
	}

	var syncOpts rsync.SyncIntervalOpts
	if m.Intervaler != nil {
		syncOpts = m.Intervaler.SyncIntervalOpts()
	} else {
		m.Log.Warning("Unable to locate Intervaler")
	}

	mount := &Mount{
		MountFolder:      m.Options,
		MountName:        m.Options.Name,
		IP:               m.IP,
		SyncIntervalOpts: syncOpts,
		EventSub:         m.EventSub,
	}

	if m.Options.OneWaySyncMount {
		mount.Type = SyncMount
	} else {
		mount.Type = FuseMount
	}

	mount.Log = MountLogger(mount, m.Log)

	if err := m.MountExisting(mount); err != nil {
		return nil, err
	}

	if err := m.MountAdder.AddMount(mount); err != nil {
		return nil, err
	}

	return mount, nil
}

func (m *Mounter) MountExisting(mount *Mount) error {
	m.emit(&Event{
		Path: mount.LocalPath,
		Type: EventMounting,
	})

	if err := m.mountExisting(mount); err != nil {
		m.emit(&Event{
			Path: mount.LocalPath,
			Type: EventMounting,
			Err:  err,
		})

		return err
	}

	m.emit(&Event{
		Path: mount.LocalPath,
		Type: EventMounted,
	})

	return nil
}

func (m *Mounter) mountExisting(mount *Mount) error {
	if err := m.IsConfigured(); err != nil {
		m.Log.Error("Mounter improperly configured. err:%s", err)
		return err
	}

	if err := m.Machine.DialOnce(); err != nil {
		m.Log.Error("Error dialing remote klient. err:%s", err)
		return util.NewKiteError(kiteerrortypes.DialingFailed, err)
	}

	if mount.KiteTracker == nil {
		mount.KiteTracker = m.KiteTracker
	}

	if mount.Intervaler == nil {
		mount.Intervaler = m.Intervaler
	}

	if mount.Type == UnknownMount {
		setTo := FuseMount
		m.Log.Notice(
			"Mount.Type is %q, setting to default:%s", mount.Type, setTo,
		)
		mount.Type = setTo
	}

	if mount.EventSub == nil {
		mount.EventSub = m.EventSub
	}

	// Create our changes channel, so that fuseMount can be told when we lose and
	// reconnect to klient.
	changeSummaries := make(chan kitepinger.ChangeSummary, 1)

	if mount.Type == FuseMount {
		// TODO: Uncomment this once fuseklient can accept a change channel.
		//changes := changeSummaryToBool(changeSummaries)
		//if err := fuseMountFolder(mount, changes); err != nil {
		if err := m.fuseMountFolder(mount); err != nil {
			return err
		}
	}

	go m.startKiteTracker(mount, changeSummaries)

	return nil
}

// fuseMountFolder uses the fuseklient library to mount the given
// folder.
func (m *Mounter) fuseMountFolder(mount *Mount) error {
	var (
		t   transport.Transport
		err error
	)

	t, err = transport.NewRemoteTransport(m.Transport, fuseTellTimeout, mount.RemotePath)
	if err != nil {
		return err
	}

	// user specifies to prefetch all content upfront
	if mount.PrefetchAll {
		dt, err := transport.NewDiskTransport(mount.CachePath)
		if err != nil {
			return err
		}

		// cast into RemoteTransport for NewDualTransport
		rt := t.(*transport.RemoteTransport)

		t = transport.NewDualTransport(rt, dt)
	}

	cf := &fuseklient.Config{
		Path:           mount.LocalPath,
		MountName:      mount.MountName,
		NoIgnore:       mount.NoIgnore,
		NoPrefetchMeta: mount.NoPrefetchMeta,
		NoWatch:        mount.NoWatch,
		Trace:          mount.Trace,
	}

	f, err := fuseklient.New(t, cf)
	if isRemotePathError(err) {
		return ErrRemotePathDoesNotExist
	} else if err != nil {
		return err
	}

	mount.MountedFS = f
	mount.Unmounter = f

	var fs *fuse.MountedFileSystem
	if fs, err = f.Mount(); err != nil {
		return err
	}

	// TODO: what context to use?
	go fs.Join(context.TODO())

	return nil
}

func (m *Mounter) startKiteTracker(mount *Mount, changeSummaries chan kitepinger.ChangeSummary) error {
	// TODO: Move this monitoring log into the KiteTracker itself
	log := m.Log.New("Kite Monitor")
	log.Info("Monitoring Klient connection..")

	m.KiteTracker.Subscribe(changeSummaries)
	m.KiteTracker.Start()
	mount.PingerSub = changeSummaries

	for summary := range changeSummaries {
		wasFailure := summary.OldStatus == kitepinger.Failure
		wasLongAgo := summary.OldStatusDur > time.Minute*5
		if wasFailure && wasLongAgo {
			// Using notice here, because although this is good, it's an important
			// event and could have UX ramifications.
			log.Notice(
				"Kite connected after extended disconnect. Disconnected for:%s",
				summary.OldStatusDur,
			)
		} else {
			log.Debug(
				"Kite connection status changed. newStatus:%s", summary.NewStatus,
			)
		}
	}

	return nil
}

// remount is an abstraction around fuseMountFolder
func (mounter *Mounter) remount(mount *Mount) error {
	// Log error and return to exit loop, since something is broke
	if err := mounter.PathUnmounter(mount.LocalPath); err != nil {
		mounter.Log.Warning("Mounter#remount unmount on %s failed: %s...ignoring error", mount.MountName, err)
	}

	if err := mounter.fuseMountFolder(mount); err != nil {
		return err
	}

	return nil
}

func (m *Mounter) emit(ev *Event) {
	if m.EventSub != nil {
		m.EventSub <- ev
	}
}

func isRemotePathError(err error) bool {
	if err == nil {
		return false
	}

	if err.Error() == "no such file or directory" {
		return true
	}

	return false
}
