package sync

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/client"
	"koding/klient/machine/index"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/notify"

	"github.com/koding/logging"
)

const (
	LocalIndexName  = "index.local"  // file name of local directory index.
	RemoteIndexName = "index.remote" // file name of remote directory index.
)

// BuildOpts represents the context that can be used by external syncers to
// build their own type. Built syncer should update indexes after syncing and
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
	Close()
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
	//   |-index.remote
	//   +-index.local
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
// is to make remote and local indexes similar.
type Sync struct {
	opts    SyncOpts
	mountID mount.ID    // identifier of synced mount.
	m       mount.Mount // single mount with absolute paths.
	log     logging.Logger

	a *Anteroom // file system event consumer.

	n notify.Notifier // object responsible for file system notifications.
	s Syncer          // object responsible for actual file synchronization.

	ridx *index.Index // known state of remote index.
	lidx *index.Index // known state of local index.
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

	// Fetch or load remote index.
	var err error
	if s.ridx, err = s.loadIdx(RemoteIndexName, s.fetchRemoteIdx); err != nil {
		return nil, err
	}

	// Create or load local index.
	if s.lidx, err = s.loadIdx(LocalIndexName, s.fetchLocalIdx); err != nil {
		return nil, err
	}

	// Update local index if needed.
	if err := s.updateLocal(); err != nil {
		return nil, err
	}

	// Create FS event consumer queue.
	s.a = NewAnteroom()

	// Create file system notification object.
	s.n, err = opts.NotifyBuilder.Build(&notify.BuildOpts{
		MountID:   mountID,
		Mount:     m,
		Cache:     s.a,
		CacheDir:  filepath.Join(s.opts.WorkDir, "data"),
		RemoteIdx: s.ridx,
		LocalIdx:  s.lidx,
	})
	if err != nil {
		s.a.Close()
		return nil, err
	}

	// Create file synchronization object.
	s.s, err = opts.SyncBuilder.Build(&BuildOpts{
		RemoteIdx: s.ridx,
		LocalIdx:  s.lidx,
	})
	if err != nil {
		s.n.Close()
		s.a.Close()
		return nil, err
	}

	return s, nil
}

// Stream creates a stream of file synchronization jobs.
func (s *Sync) Stream() <-chan Execer {
	return s.s.ExecStream(s.a.Events())
}

// Info returns the current status of supervised indexes.
func (s *Sync) Info() *Info {
	items, queued := s.a.Status()

	return &Info{
		ID:           s.mountID,
		Mount:        s.m,
		SyncCount:    s.lidx.Count(-1),
		AllCount:     s.ridx.Count(-1),
		SyncDiskSize: s.lidx.DiskSize(-1),
		AllDiskSize:  s.ridx.DiskSize(-1),
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
func (s *Sync) Close() {
	s.n.Close()
	s.s.Close()
	s.a.Close()
}

// loadIdx reads named index from synced working directory. If index file does
// not exist, it is fetched by calling provided `fetchIdx` function and saved to
// provided path.
func (s *Sync) loadIdx(name string, fetchIdx idxFunc) (*index.Index, error) {
	path := filepath.Join(s.opts.WorkDir, name)
	f, err := os.Open(path)
	if os.IsNotExist(err) {
		idx, err := fetchIdx()
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

// idxFunc is a function used to fetch or update index.
type idxFunc func() (*index.Index, error)

// fetchRemoteIdx downloads remote index.
func (s *Sync) fetchRemoteIdx() (*index.Index, error) {
	spv := client.NewSupervised(s.opts.ClientFunc, 30*time.Second)
	return spv.MountGetIndex(s.m.RemotePath)
}

// fetchLocalIdx always scans mount cache directory and creates new index.
func (s *Sync) fetchLocalIdx() (*index.Index, error) {
	return index.NewIndexFiles(filepath.Join(s.opts.WorkDir, "data"))
}

// updateLocal updates local index and saves it to cache directory.
func (s *Sync) updateLocal() error {
	dataPath := filepath.Join(s.opts.WorkDir, "data")
	cs := s.lidx.Compare(dataPath)

	if len(cs) == 0 {
		return nil
	}

	s.lidx.Apply(dataPath, cs)
	return index.SaveIndex(s.lidx, filepath.Join(s.opts.WorkDir, LocalIndexName))
}
