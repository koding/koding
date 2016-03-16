package mount

import (
	"errors"
	"koding/fuseklient"
	"koding/fuseklient/transport"
	"koding/klient/kiteerrortypes"
	"koding/klient/remote/kitepinger"
	"koding/klient/remote/req"
	"koding/klient/remote/rsync"
	"koding/klient/util"
	"time"

	"golang.org/x/net/context"

	"github.com/koding/kite/dnode"
	"github.com/koding/logging"
)

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

// MounterTransport is the transport that the Mounter uses to communicate with
// the remote machine.
type MounterTransport interface {
	Dial() error
	Tell(string, ...interface{}) (*dnode.Partial, error)
	TellWithTimeout(string, time.Duration, ...interface{}) (*dnode.Partial, error)
}

// Mounter is responsible for actually mounting fuse mounts from Klient.
type Mounter struct {
	Log logging.Logger

	// The options for this Mounter, such as LocalFolder, etc.
	Options req.MountFolder

	// The IP of the remote machine.
	IP string

	// The KitePinger that the remote machine this Mounter uses, will deal with.
	KitePinger kitepinger.KitePinger

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

	if m.KitePinger == nil {
		return util.KiteErrorf(kiteerrortypes.MissingArgument, "Missing KitePinger")
	}

	if m.Transport == nil {
		return util.KiteErrorf(kiteerrortypes.MissingArgument, "Missing Transport")
	}

	if m.PathUnmounter == nil {
		return util.KiteErrorf(kiteerrortypes.MissingArgument, "Missing Unmounter")
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
	}

	if err := m.MountExisting(mount); err != nil {
		return nil, err
	}

	if err := m.MountAdder.AddMount(mount); err != nil {
		return nil, err
	}

	return mount, nil
}

func (m *Mounter) MountExisting(mount *Mount) error {
	if err := m.IsConfigured(); err != nil {
		m.Log.Error("Mounter improperly configured. err:%s", err)
		return err
	}

	if err := m.Transport.Dial(); err != nil {
		m.Log.Error("Error dialing remote klient. err:%s", err)
		return util.NewKiteError(kiteerrortypes.DialingFailed, err)
	}

	if mount.KitePinger == nil {
		mount.KitePinger = m.KitePinger
	}

	if mount.Intervaler == nil {
		mount.Intervaler = m.Intervaler
	}

	// Create our changes channel, so that fuseMount can be told when we lose and
	// reconnect to klient.
	changeSummaries := make(chan kitepinger.ChangeSummary, 1)

	// TODO: Uncomment this once fuseklient can accept a change channel.
	//changes := changeSummaryToBool(changeSummaries)
	//if err := fuseMountFolder(mount, changes); err != nil {
	if err := m.fuseMountFolder(mount); err != nil {
		return err
	}

	go m.watchClientAndReconnect(mount, changeSummaries)

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
		Debug:          true, // turn on debug permanently till v1
	}

	f, err := fuseklient.New(t, cf)
	if err != nil {
		return err
	}

	mount.MountedFS = f
	mount.Unmounter = f

	fs, err := f.Mount()
	if err != nil {
		return err
	}

	// TODO: what context to use?
	go fs.Join(context.TODO())

	return nil
}

func (m *Mounter) watchClientAndReconnect(mount *Mount, changeSummaries chan kitepinger.ChangeSummary) error {
	m.Log.Info("Monitoring Klient connection..")

	m.KitePinger.Subscribe(changeSummaries)
	m.KitePinger.Start()
	mount.PingerSub = changeSummaries

	for summary := range changeSummaries {
		if err := m.handleChangeSummary(mount, summary); err != nil {
			return err
		}
	}

	return nil
}

func (m *Mounter) handleChangeSummary(mount *Mount, summary kitepinger.ChangeSummary) error {
	log := m.Log.New("handleChangeSummary")

	if summary.OldStatus == kitepinger.Failure && summary.OldStatusDur > time.Minute*30 {
		// Using warning here, because although this is good, it's an important
		// event and could have UX ramifications.
		log.Warning(
			"Remounting directory after reconnect. Disconnected for:%s", summary.OldStatusDur,
		)

		// Log error and return to exit loop, since something is broke
		if err := m.PathUnmounter(mount.LocalPath); err != nil {
			log.Error("Failed to unmount. err:%s", err)
			return err
		}

		if err := m.fuseMountFolder(mount); err != nil {
			log.Error("Failed to mount. err:%s", err)
			return err
		}
	}

	return nil
}

// changeSummaryToBool is a simple func that converts a ChangeSummary channel to a
// bool channel, based on Success or Failure (success is true, failure is false).
func changeSummaryToBool(s chan kitepinger.ChangeSummary) <-chan bool {
	b := make(chan bool)
	go func() {
		for change := range s {
			switch change.NewStatus {
			case kitepinger.Success:
				b <- true
			case kitepinger.Failure:
				b <- false
			}
		}
		close(b)
	}()
	return b
}
