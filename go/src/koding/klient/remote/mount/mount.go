package mount

import (
	"koding/fuseklient"
	"koding/klient/kiteerrortypes"
	"koding/klient/remote/kitepinger"
	"koding/klient/remote/req"
	"koding/klient/remote/rsync"
	"koding/klient/util"
)

var (
	// Returned by various methods if the requested mount cannot be found.
	ErrMountNotFound error = util.KiteErrorf(
		kiteerrortypes.MountNotFound, "Mount not found",
	)
)

// Mount stores information about mounted folders, and is both with
// to various Remote.* kite methods as well as being saved in
// klient's storage.
type Mount struct {
	// The embedded MountFolder
	req.MountFolder

	IP        string `json:"ip"`
	MountName string `json:"mountName"`

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
	KitePinger kitepinger.KitePinger `json:"-"`

	MountedFS fuseklient.FS `json:"-"`

	// mockable interfaces and types, used for testing and abstracting the environment
	// away.

	// the mountedFs Unmounter
	Unmounter interface {
		Unmount() error
	} `json:"-"`
}
