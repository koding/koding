package mount

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"sync"
	"time"

	"koding/klient/config"
	"koding/klient/machine"
	"koding/klient/machine/client"
	"koding/klient/machine/index"
	"koding/klient/machine/index/filter"
	"koding/klient/machine/mount/notify"
	"koding/klient/machine/mount/prefetch"
	msync "koding/klient/machine/mount/sync"
	"koding/klient/machine/mount/sync/history"
	"koding/klient/machine/mount/sync/supervised"

	"github.com/koding/logging"
)

// IndexFileName is a file name of managed directory index.
const IndexFileName = "index"

// DefaultFilter defines a default filter used to skip changes from being
// synchronized.
var DefaultFilter filter.Filter = filter.MultiFilter{
	filter.OsSkip(filter.DirectorySkip(".Trash"), "darwin"),     // OSX trash directory.
	filter.OsSkip(filter.DirectorySkip(".Trashes"), "darwin"),   // OSX trash directory.
	filter.OsSkip(filter.DirectorySkip(".fseventsd"), "darwin"), // FSEvents notify.
	filter.PathSuffixSkip(".git/index.lock"),                    // git index lock file.
	filter.PathSuffixSkip(".git/index"),                         // git index.
	filter.PathSuffixSkip(".git/refs/stash.lock"),               // git stash lock file.
	filter.PathSuffixSkip(".git/HEAD.lock"),                     // git HEAD lock.
	filter.PathSuffixSkip(".git/ORIG_HEAD.lock"),                // git ORIG_HEAD lock.
	filter.NewRegexSkip(`\.git/refs/heads/[^\s]+\.lock$`),       // git branch lock.
	filter.NewRegexSkip(`\.git/index\.stash\.\d+\.lock$`),       // git stash ref. lock.
	filter.NewRegexSkip(`\.git/objects/pack/tmp_pack_[^/]+`),    // temporary git files.
}

// Info stores information about current mount status.
type Info struct {
	ID    ID    `json:"id"`    // Mount ID.
	Mount Mount `json:"mount"` // Mount paths stored in absolute form.

	Count    int `json:"count"`    // Number of synced files.
	CountAll int `json:"countAll"` // Number of all files handled by mount.

	DiskSize    int64 `json:"diskSize"`    // Total size of synced files.
	DiskSizeAll int64 `json:"diskSizeAll"` // Size of all files handled by mount.

	Queued  int `json:"queued"`  // Number of files waiting for synchronization.
	Syncing int `json:"syncing"` // Number of files being synced.
}

// Options are the options used to configure Sync object.
type Options struct {
	// ClientFunc is a factory for dynamic clients.
	ClientFunc client.DynamicClientFunc

	// SSHFunc is a factory for client SSH addresses.
	SSHFunc msync.DynamicSSHFunc

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
	SyncBuilder msync.Builder

	// Filter defines a file filter for mount syncer. If nil, DefaultFilter
	// will be used.
	Filter filter.Filter

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
	mountID ID    // identifier of synced mount.
	m       Mount // single mount with absolute paths.
	log     logging.Logger

	a *Anteroom // file system event consumer.

	once   sync.Once     // used for closing closeC chan.
	closeC chan struct{} // closed when sync object is closed.

	n notify.Notifier // object responsible for file system notifications.
	s msync.Syncer    // object responsible for actual file synchronization.

	idx *index.Index // known state of managed index.
	iu  *IdxUpdate   // local index updater.
}

// Idx returns Sync index.
func (s *Sync) Idx() *index.Index {
	return s.idx
}

// NewSync creates a new sync instance for a given mount. It ensures basic mount
// directory structure. This function is blocking.
func NewSync(mountID ID, m Mount, opts Options) (*Sync, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	s := &Sync{
		opts:    opts,
		mountID: mountID,
		m:       m,
		closeC:  make(chan struct{}),
	}

	if opts.Filter == nil {
		s.opts.Filter = DefaultFilter
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

	// Path to index file.
	idxPath := filepath.Join(s.opts.WorkDir, IndexFileName)

	// Fetch remote index which will become managed one.
	var err error
	if s.idx, err = s.loadIdx(idxPath); err != nil {
		return nil, err
	}

	// Periodically flush memory index to disk.
	s.iu = NewIdxUpdate(idxPath, s.idx.Clone(), 60*time.Second, s.log)

	// Create FS event consumer queue.
	s.a = NewAnteroom()

	// Create file system notification object.
	s.n, err = opts.NotifyBuilder.Build(&notify.BuildOpts{
		ID:         string(mountID),
		Path:       m.Path,
		RemotePath: m.RemotePath,
		Cache:      s.a,
		CacheDir:   s.CacheDir(),
		Index:      s.idx,
		Log:        s.log,
	})
	if err != nil {
		return nil, nonil(err, s.a.Close(), s.iu.Close())
	}

	// Use supervised syncer to gracefully handle client disconnections.
	sb := supervised.Builder{
		Inner: opts.SyncBuilder,
	}

	// Create file synchronization object.
	syncer, err := sb.Build(&msync.BuildOpts{
		RemoteDir:     m.RemotePath,
		CacheDir:      s.CacheDir(),
		ClientFunc:    s.opts.ClientFunc,
		SSHFunc:       s.opts.SSHFunc,
		IndexSyncFunc: s.indexSync(),
	})
	if err != nil {
		return nil, nonil(err, s.n.Close(), s.a.Close(), s.iu.Close())
	}

	// Enable syncing history for all mounts.
	s.s = history.NewHistory(syncer, config.Konfig.Mount.Inspect.History)

	return s, nil
}

// Anteroom gives the sync's anteroom.
func (s *Sync) Anteroom() *Anteroom { return s.a }

// Stream creates a stream of file synchronization jobs.
func (s *Sync) Stream() <-chan msync.Execer {
	evC := make(chan *msync.Event)

	go func() {
		// Event loop will be closed once Anteroom is closed.
		evSourceC := s.a.Events()
		for ev := range evSourceC {
			if err := s.opts.Filter.Check(ev.Change().Path()); err != nil {
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
	items, synced := s.a.Status()

	return &Info{
		ID:          s.mountID,
		Mount:       s.m,
		Count:       s.idx.Tree().ExistCount(),
		CountAll:    s.idx.Tree().Count(),
		DiskSize:    s.idx.Tree().ExistDiskSize(),
		DiskSizeAll: s.idx.Tree().DiskSize(),
		Queued:      items,
		Syncing:     synced,
	}
}

// History gets recent history of synchronized files.
func (s *Sync) History() ([]*history.Record, error) {
	if h, ok := s.s.(*history.History); ok {
		return h.Get(), nil
	}

	return nil, errors.New("synchronization history is unavailable")
}

// IndexDebug gets current index tree debug information.
func (s *Sync) IndexDebug() []index.Debug {
	return s.idx.Debug()
}

// Diagnose diagnoses the mount looking for inconsistent or invalid states.
func (s *Sync) Diagnose() []string {
	return s.idx.Diagnose(s.CacheDir())
}

// CacheDir returns the name of mount cache directory.
func (s *Sync) CacheDir() string {
	return filepath.Join(s.opts.WorkDir, "data")
}

// UpdateIndex rescans the cache directory and sets all recorded changes to
// managed index. This function allows to express the current state of
// synchronized files inside index structure.
func (s *Sync) UpdateIndex() {
	// Dont filter during merge since we want index to store all files.
	cs, err := s.idx.Merge(s.CacheDir(), nil)
	if err != nil {
		s.log.Error("Cannot update in-memory index: %v", err)
	}

	for i := range cs {
		// However, we dont want to synchronize unwanted files.
		if err := s.opts.Filter.Check(cs[i].Path()); err != nil {
			continue
		}

		s.a.Commit(cs[i])
	}
}

// Prefetch creates a strategy with prefetch command to run.
func (s *Sync) Prefetch(av []string) (p prefetch.Prefetch, err error) {
	spv := client.NewSupervised(s.opts.ClientFunc, 30*time.Second)
	// Get remote username.
	username, err := spv.CurrentUser()
	if err != nil {
		return p, err
	}

	// Get remote host and port.
	host, port, err := s.opts.SSHFunc()
	if err != nil {
		return p, err
	}

	opts := prefetch.Options{
		SourcePath:      s.m.RemotePath,
		DestinationPath: s.CacheDir(),
		Username:        username,
		Host:            host,
		SSHPort:         port,
	}

	return prefetch.DefaultStrategy.Select(opts, av, s.idx), nil
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

	return nonil(s.n.Close(), s.s.Close(), s.a.Close(), s.iu.Close())
}

// loadIdx reads named index from synced working directory. If index file does
// not exist, it will be downloaded from remote machine and saved.
func (s *Sync) loadIdx(path string) (*index.Index, error) {
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

func (s *Sync) indexSync() msync.IndexSyncFunc {
	cacheDir := filepath.Join(s.opts.WorkDir, "data")

	return func(c *index.Change) {
		s.idx.Sync(cacheDir, c)
		s.iu.Update(cacheDir, c)
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
