package mount

import (
	"koding/fuseklient"
	"koding/klient/kiteerrortypes"
	"koding/klient/remote/kitepinger"
	"koding/klient/remote/req"
	"koding/klient/remote/rsync"
	"koding/klient/util"

	"github.com/koding/logging"
)

var (
	// Returned by various methods if the requested mount cannot be found.
	ErrMountNotFound error = util.KiteErrorf(
		kiteerrortypes.MountNotFound, "Mount not found",
	)
)

type MountType int

const (
	UnknownMount MountType = iota
	FuseMount
	SyncMount
)

// Mount stores information about mounted folders, and is both with
// to various Remote.* kite methods as well as being saved in
// klient's storage.
type Mount struct {
	// The embedded MountFolder
	req.MountFolder

	IP        string    `json:"ip"`
	MountName string    `json:"mountName"`
	Type      MountType `json:"mountType"`

	// The options used for the local Intervaler. Used to store and retrieve from
	// the database.
	SyncIntervalOpts rsync.SyncIntervalOpts `json:"syncIntervalOpts"`

	// The intervaler for this mount, used to update the remote.cache, if it exists.
	//
	// Note: If remote.cache is not called, or not called with an interval, this
	// will be null. Check before using.
	Intervaler rsync.SyncIntervaler `json:"-"`

	// The channel that sends notification of connection statuses on. This may be
	// nil unless the Mount is actively started and subscribed.
	PingerSub chan kitepinger.ChangeSummary `json:"-"`

	// A kitepinger reference from the parent machine, so that Mounts can unsub as
	// needed.
	KiteTracker *kitepinger.PingTracker `json:"-"`

	MountedFS fuseklient.FS `json:"-"`

	Log logging.Logger `json:"-"`

	// EventSub receives events when paths get mounted / unmounted.
	EventSub chan<- *Event `json:"-"`

	// mockable interfaces and types, used for testing and abstracting the environment
	// away.

	// the mountedFs Unmounter
	Unmounter interface {
		Unmount() error
	} `json:"-"`
}

func (m *Mount) Unmount() error {
	// Nothing to do if this is a SyncMount
	if m.Type == SyncMount {
		return nil
	}

	m.emit(&Event{
		Path: m.LocalPath,
		Type: EventUnmounting,
	})

	if err := m.unmount(); err != nil {
		m.emit(&Event{
			Path: m.LocalPath,
			Type: EventUnmounting,
			Err:  err,
		})

		return err
	}

	m.emit(&Event{
		Path: m.LocalPath,
		Type: EventUnmounted,
	})

	return nil
}

func (m *Mount) unmount() (err error) {
	if m.Unmounter != nil {
		err = m.Unmounter.Unmount()
	} else {
		err = fuseklient.Unmount(m.LocalPath)
	}

	// Ignoring this error, since this fails when it's unable to find mount on
	// path, ie. we're already at the desired state we want to be in.
	if err != nil {
		m.Log.Warning("Mount#Unmount on %s failed: %s...ignoring error.", m.LocalPath, err)
	}

	return nil
}

func (m *Mount) emit(ev *Event) {
	if m.EventSub != nil {
		m.EventSub <- ev
	}
}

func MountLogger(m *Mount, l logging.Logger) logging.Logger {
	return l.New("mount").New(
		"name", m.MountName,
		"path", m.LocalPath,
	)
}

func (mt MountType) String() string {
	switch mt {
	case UnknownMount:
		return "UnknownMount"
	case FuseMount:
		return "FuseMount"
	case SyncMount:
		return "SyncMount"
	default:
		return "Invalid MountType"
	}
}
