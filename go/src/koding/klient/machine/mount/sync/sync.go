package sync

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sync"
	"time"

	"koding/klient/fs"
	"koding/klient/machine"
	"koding/klient/machine/client"
	"koding/klient/machine/index"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/notify"
	"koding/klient/machine/transport/rsync"

	"github.com/koding/logging"
)

// IndexFileName is a file name of managed directory index.
const IndexFileName = "index"

// DynamicSSHFunc locates the remote host which ssh should connect to.
type DynamicSSHFunc func() (host string, port int, err error)

// IndexSyncFunc is a function that must be called by syncer immediately after
// synchronization process. It is used to update index.
type IndexSyncFunc func(*index.Change)

// BuildOpts represents the context that can be used by external syncers to
// build their own type. Built syncer should update the index after syncing and
// manage received events.
type BuildOpts struct {
	Mount    mount.Mount // single mount with absolute paths.
	CacheDir string      // absolute path to locally cached files.

	ClientFunc    client.DynamicClientFunc // factory for dynamic clients.
	SSHFunc       DynamicSSHFunc           // dynamic getter for machine SSH address.
	IndexSyncFunc IndexSyncFunc            // callback used to update index.
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

	Count    int // Number of synced files.
	CountAll int // Number of all files handled by mount.

	DiskSize    int64 // Total size of synced files.
	DiskSizeAll int64 // Size of all files handled by mount.

	Queued  int // Number of files waiting for synchronization.
	Syncing int // Number of files being synced.
}

// Options are the options used to configure Sync object.
type Options struct {
	// ClientFunc is a factory for dynamic clients.
	ClientFunc client.DynamicClientFunc

	// SSHFunc is a factory for client SSH addresses.
	SSHFunc DynamicSSHFunc

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
func (opts *Options) Valid() error {
	if opts == nil {
		return errors.New("mount sync options are nil")
	}
	if opts.ClientFunc == nil {
		return errors.New("nil dynamic client function")
	}
	if opts.SSHFunc == nil {
		return errors.New("nil dynamic SSH address function")
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

// Sync stores and synchronizes a single mount. The main goal of its logic
// is to make stored index and cache directory consistent.
type Sync struct {
	opts    Options
	mountID mount.ID    // identifier of synced mount.
	m       mount.Mount // single mount with absolute paths.
	log     logging.Logger

	a *Anteroom // file system event consumer.

	sk     Skipper       // local to remote file skippers.
	once   sync.Once     // used for closing closeC chan.
	closeC chan struct{} // closed when sync object is closed.

	n notify.Notifier // object responsible for file system notifications.
	s Syncer          // object responsible for actual file synchronization.

	idx *index.Index // known state of managed index.
}

// NewSync creates a new sync instance for a given mount. It ensures basic mount
// directory structure. This function is blocking.
func NewSync(mountID mount.ID, m mount.Mount, opts Options) (*Sync, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	s := &Sync{
		opts:    opts,
		mountID: mountID,
		m:       m,
		sk:      DefaultSkipper,
		closeC:  make(chan struct{}),
	}

	if opts.Log != nil {
		s.log = opts.Log.New("sync")
	} else {
		s.log = machine.DefaultLogger.New("sync")
	}

	// Create directory structure if it doesn't exist.
	if err := os.MkdirAll(s.CacheDir(), 0755); err != nil {
		return nil, err
	}

	// Fetch remote index which will become managed one.
	var err error
	if s.idx, err = s.loadIdx(IndexFileName); err != nil {
		return nil, err
	}

	// Initialize skippers.
	if err = s.sk.Initialize(s.CacheDir()); err != nil {
		s.log.Warning("File local filters were not initialized: %s", err)
	}

	// Check current state of synchronization and set promises.
	s.UpdateIndex()

	// Create FS event consumer queue.
	s.a = NewAnteroom()

	// Create file system notification object.
	s.n, err = opts.NotifyBuilder.Build(&notify.BuildOpts{
		MountID:  mountID,
		Mount:    m,
		Cache:    s.a,
		CacheDir: s.CacheDir(),
		DiskInfo: s.diskInfo(),
		Index:    s.idx,
	})
	if err != nil {
		return nil, nonil(err, s.a.Close())
	}

	// Create file synchronization object.
	s.s, err = opts.SyncBuilder.Build(&BuildOpts{
		Mount:         m,
		CacheDir:      s.CacheDir(),
		ClientFunc:    s.opts.ClientFunc,
		SSHFunc:       s.opts.SSHFunc,
		IndexSyncFunc: s.indexSync(),
	})
	if err != nil {
		return nil, nonil(err, s.n.Close(), s.a.Close())
	}

	return s, nil
}

// Stream creates a stream of file synchronization jobs.
func (s *Sync) Stream() <-chan Execer {
	evC := make(chan *Event)

	go func() {
		// Event loop will be closed once Anteroom is closed.
		evSourceC := s.a.Events()
		for ev := range evSourceC {
			if s.sk.IsSkip(ev) {
				ev.Done()
				continue
			}

			select {
			case evC <- ev:
			case <-s.closeC:
				return
			}
		}
	}()

	return s.s.ExecStream(evC)
}

// Info returns the current mount synchronization status.
func (s *Sync) Info() *Info {
	items, queued := s.a.Status()

	return &Info{
		ID:          s.mountID,
		Mount:       s.m,
		Count:       s.idx.Count(-1),
		CountAll:    s.idx.CountAll(-1),
		DiskSize:    s.idx.DiskSize(-1),
		DiskSizeAll: s.idx.DiskSizeAll(-1),
		Queued:      items,
		Syncing:     items - queued,
	}
}

// CacheDir returns the name of mount cache directory.
func (s *Sync) CacheDir() string {
	return filepath.Join(s.opts.WorkDir, "data")
}

// UpdateIndex rescans the cache directory and sets all recorded changes to
// managed index. This function allows to express the current state of
// synchronized files inside index structure.
func (s *Sync) UpdateIndex() {
	s.idx.Merge(s.CacheDir())
}

// FetchCmd creates a strategy with prefetch command to run.
func (s *Sync) FetchCmd() (count, diskSize int64, cmd *rsync.Command, err error) {
	spv := client.NewSupervised(s.opts.ClientFunc, 30*time.Second)
	// Get remote username.
	username, err := spv.CurrentUser()
	if err != nil {
		return 0, 0, nil, err
	}

	// Get remote host and port.
	host, port, err := s.opts.SSHFunc()
	if err != nil {
		return 0, 0, nil, err
	}

	cmd = &rsync.Command{
		Download:        true,
		SourcePath:      s.m.RemotePath + "/",
		DestinationPath: s.CacheDir() + "/",
		Username:        username,
		Host:            host,
		SSHPort:         port,
	}

	// Look for git VCS.
	if n, ok := s.idx.LookupAll(".git"); ok && n.IsDir() {
		// Download only git data.
		cmd.SourcePath += ".git/"
		cmd.DestinationPath += ".git/"

		count = int64(n.CountAll(-1))
		diskSize = n.DiskSizeAll(-1)
	} else {
		count = int64(s.idx.CountAll(-1))
		diskSize = s.idx.DiskSizeAll(-1)
	}

	return count, diskSize, cmd, nil
}

// Drop closes synced mount and cleans up all resources acquired by it.
func (s *Sync) Drop() error {
	s.Close()
	return os.RemoveAll(s.opts.WorkDir)
}

// Close closes memory resources acquired by Sync object.
func (s *Sync) Close() error {
	s.once.Do(func() {
		close(s.closeC)
	})

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

func (s *Sync) indexSync() IndexSyncFunc {
	cacheDir := filepath.Join(s.opts.WorkDir, "data")

	return func(c *index.Change) {
		s.idx.Sync(cacheDir, c)
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
