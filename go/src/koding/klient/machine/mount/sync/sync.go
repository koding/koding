package sync

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	"koding/klient/fs"
	"koding/klient/machine"
	"koding/klient/machine/client"
	"koding/klient/machine/index"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/notify"

	"github.com/koding/logging"
)

// IndexFileName is a file name of managed directory index.
const IndexFileName = "index"

// BuildOpts represents the context that can be used by external syncers to
// build their own type. Built syncer should update the index after syncing and
// manage received events.
type BuildOpts struct {
	RemoteIdx *index.Index // known state of remote index.
	LocalIdx  *index.Index // known state of local index.
}

// Builder represents a factory method which external syncers must implement in
// order to create their instances.
type Builder interface {
	// Build uses provided build options to create Syncer instance.
	Build(opts *BuildOpts) (Syncer, error)
}

// Execer represents an interface which must be implemented by sync event
// produced by external syncer.
type Execer interface {
	// Exec starts synchronization of stored syncing job. It should update
	// indexes and clean up synced Event.
	Exec() error

	// fmt.Stringer defines human readable information about the event.
	fmt.Stringer
}

// Syncer is an interface which must be implemented by external syncer.
type Syncer interface {
	// ExecStream is a method that wraps received event with custom
	// synchronization logic.
	ExecStream(<-chan *Event) <-chan Execer

	// Close cleans up syncer resources.
	io.Closer
}

// Info stores information about current mount status.
type Info struct {
	ID    mount.ID    // Mount ID.
	Mount mount.Mount // Mount paths stored in absolute form.

	SyncCount int // Number of synced files.
	AllCount  int // Number of all files handled by mount.

	SyncDiskSize int64 // Total size of synced files.
	AllDiskSize  int64 // Size of all files handled by mount.

	Queued  int // Number of files waiting for synchronization.
	Syncing int // Number of files being synced.
}

// SyncOpts are the options used to configure Sync object.
type SyncOpts struct {
	// ClientFunc is a factory for dynamic clients.
	ClientFunc client.DynamicClientFunc

	// WorkDir is a working directory that will be used by syncs object. The
	// directory structure for single mount with ID will look like:
	//
	//   WorkDir
	//   |-data
	//   | +-... // mounted directory cache.
	//   +-index
	//
	WorkDir string

	// NotifyBuilder defines a factory used to build file system notification
	// objects.
	NotifyBuilder notify.Builder

	// SyncBuilder defines a factory used to build object which will be
	// responsible for syncing files.
	SyncBuilder Builder

	// Log is used for logging. If nil, default logger will be created.
	Log logging.Logger
}

// Valid checks if provided options are correct.
func (opts *SyncOpts) Valid() error {
	if opts == nil {
		return errors.New("mount sync options are nil")
	}
	if opts.ClientFunc == nil {
		return errors.New("nil dynamic client function")
	}
	if opts.NotifyBuilder == nil {
		return errors.New("file system notification builder is nil")
	}
	if opts.SyncBuilder == nil {
		return errors.New("synchronization builder is nil")
	}
	if opts.WorkDir == "" {
		return errors.New("working directory is not set")
	}

	return nil
}

// Sync stores and synchronizes single mount. The main goal of its logic
// is to make stored index and cache directory consistent.
type Sync struct {
	opts    SyncOpts
	mountID mount.ID    // identifier of synced mount.
	m       mount.Mount // single mount with absolute paths.
	log     logging.Logger

	a *Anteroom // file system event consumer.

	n notify.Notifier // object responsible for file system notifications.
	s Syncer          // object responsible for actual file synchronization.

	idx *index.Index // known state of managed index.
}

// NewSync creates a new sync instance for a given mount. It ensures basic mount
// directory structure. This function is blocking.
func NewSync(mountID mount.ID, m mount.Mount, opts SyncOpts) (*Sync, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	s := &Sync{
		opts:    opts,
		mountID: mountID,
		m:       m,
	}

	if opts.Log != nil {
		s.log = opts.Log.New("sync")
	} else {
		s.log = machine.DefaultLogger.New("sync")
	}

	// Create directory structure if it doesn't exist.
	if err := os.MkdirAll(filepath.Join(s.opts.WorkDir, "data"), 0755); err != nil {
		return nil, err
	}

	// Fetch remote index which will become managed one.
	var err error
	if s.idx, err = s.loadIdx(IndexFileName); err != nil {
		return nil, err
	}

	// TODO(ppknap): refresh loaded index with current state.

	// Create FS event consumer queue.
	s.a = NewAnteroom()

	// Create file system notification object.
	s.n, err = opts.NotifyBuilder.Build(&notify.BuildOpts{
		MountID:  mountID,
		Mount:    m,
		Cache:    s.a,
		CacheDir: filepath.Join(s.opts.WorkDir, "data"),
		DiskInfo: s.diskInfo(),
		Index:    s.idx,
	})
	if err != nil {
		return nil, nonil(err, s.a.Close())
	}

	// Create file synchronization object.
	s.s, err = opts.SyncBuilder.Build(&BuildOpts{
		Index: s.idx,
	})
	if err != nil {
		return nil, nonil(err, s.n.Close(), s.a.Close())
	}

	return s, nil
}

// Stream creates a stream of file synchronization jobs.
func (s *Sync) Stream() <-chan Execer {
	return s.s.ExecStream(s.a.Events())
}

// Info returns the current mount synchronization status.
func (s *Sync) Info() *Info {
	items, queued := s.a.Status()

	return &Info{
		ID:           s.mountID,
		Mount:        s.m,
		SyncCount:    0, // TODO(ppknap) s.lidx.Count(-1),
		AllCount:     s.idx.Count(-1),
		SyncDiskSize: 0, // TODO(ppknap) s.lidx.DiskSize(-1),
		AllDiskSize:  s.idx.DiskSize(-1),
		Queued:       items,
		Syncing:      items - queued,
	}
}

// Drop closes synced mount and cleans up all resources acquired by it.
func (s *Sync) Drop() error {
	s.Close()
	return os.RemoveAll(s.opts.WorkDir)
}

// Close closes memory resources acquired by Sync object.
func (s *Sync) Close() error {
	return nonil(s.n.Close(), s.s.Close(), s.a.Close())
}

// loadIdx reads named index from synced working directory. If index file does
// not exist, it will be downloaded from remote machine and saved.
func (s *Sync) loadIdx(name string) (*index.Index, error) {
	path := filepath.Join(s.opts.WorkDir, name)
	f, err := os.Open(path)
	if os.IsNotExist(err) {
		// Downloads remote index.
		spv := client.NewSupervised(s.opts.ClientFunc, 30*time.Second)
		idx, err := spv.MountGetIndex(s.m.RemotePath)
		if err != nil {
			return nil, err
		}

		return idx, index.SaveIndex(idx, path)
	} else if err != nil {
		return nil, err
	}
	defer f.Close()

	idx := index.NewIndex()
	return idx, json.NewDecoder(f).Decode(idx)
}

func (s *Sync) diskInfo() notify.DiskInfo {
	const (
		rt = 10 * time.Second // How long client should wait for valid connection.
		ct = 5 * time.Minute  // How long client responses will be cached.
	)

	cached := client.NewCached(client.NewSupervised(s.opts.ClientFunc, rt), ct)

	return func() (fs.DiskInfo, error) {
		return cached.DiskInfo(s.m.RemotePath)
	}
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}

	return nil
}
