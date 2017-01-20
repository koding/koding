package mount

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/client"
	"koding/klient/machine/index"

	"github.com/koding/logging"
)

const (
	LocalIndexName  = "index.local"  // file name of local directory index.
	RemoteIndexName = "index.remote" // file name of remote directory index.
)

// DynamicClientFunc is an adapter that allows to dynamically provide clients
// from a given mount ID. Error should be of ErrMountNotFound type when it is
// not possible to find any client based on a given mount.
type DynamicClientFunc func(ID) (client.Client, error)

// Info stores information about current mount status.
type Info struct {
	ID    ID    // Mount ID.
	Mount Mount // Mount paths stored in absolute form.

	SyncCount int // Number of synced files.
	AllCount  int // Number of all files handled by mount.

	SyncDiskSize int64 // Total size of synced files.
	AllDiskSize  int64 // Size of all files handled by mount.
}

// SyncOpts are the options used to configure Syncs object.
type SyncOpts struct {
	// ClientFunc is a factory for dynamic clients.
	ClientFunc DynamicClientFunc

	// WorkDir is a working directory that will be used by syncs object. The
	// directory structure for single mount with ID will look like:
	//
	//   WorkDir
	//   +-mount-<ID>
	//     |-data
	//     | +-... // mounted directory cache.
	//     |-index.remote
	//     +-index.local
	//
	WorkDir string

	// Log is used for logging. If nil, default logger will be created.
	Log logging.Logger
}

// Valid checks if provided options are correct.
func (opts *SyncOpts) Valid() error {
	if opts.ClientFunc == nil {
		return errors.New("nil dynamic client function")
	}

	if opts.WorkDir == "" {
		return errors.New("working directory is not set")
	}

	if _, err := os.Stat(opts.WorkDir); err != nil {
		return fmt.Errorf("invalid working directory %q: %s", opts.WorkDir, err)
	}

	return nil
}

// Sync synchronizes and manages one or more directories. This type is
// responsible for ensuring that remote and local directories are as much
// similar as possible.
type Sync struct {
	opts SyncOpts
	log  logging.Logger

	mu    sync.RWMutex
	syncs map[ID]*synced
}

// NewSync creates a new Sync instance from the given options.
func NewSync(opts SyncOpts) (*Sync, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	s := &Sync{
		opts:  opts,
		syncs: make(map[ID]*synced),
	}

	if opts.Log != nil {
		s.log = opts.Log.New("sync")
	} else {
		s.log = machine.DefaultLogger.New("sync")
	}

	return s, nil
}

// Add starts synchronization between remote and local directories. It creates
// all necessary cache files if they are not present.
func (s *Sync) Add(id ID, m Mount) error {
	s.mu.RLock()
	sd, ok := s.syncs[id]
	s.mu.RUnlock()

	if ok {
		return fmt.Errorf("mount with ID %s already exists (%s)", id, sd.m)
	}

	sd, err := newSynced(id, m, &s.opts)
	if err != nil {
		return err
	}

	s.mu.Lock()
	if _, ok := s.syncs[id]; ok {
		s.mu.Unlock()
		return fmt.Errorf("mount with ID %s added twice", id)
	}
	s.syncs[id] = sd
	s.mu.Unlock()

	return nil
}

// Info returns the current state of mount with provided ID.
func (s *Sync) Info(id ID) (*Info, error) {
	s.mu.RLock()
	sd, ok := s.syncs[id]
	s.mu.RUnlock()

	if !ok {
		return nil, ErrMountNotFound
	}

	return sd.info(), nil
}

// Drop removes the mount and clean ups the resources it uses.
func (s *Sync) Drop(id ID) (err error) {
	s.mu.Lock()
	sd, ok := s.syncs[id]
	delete(s.syncs, id)
	s.mu.Unlock()

	if !ok {
		return nil
	}

	if err = sd.drop(); err != nil {
		// Drop failed - put synced back to the map.
		s.mu.Lock()
		s.syncs[id] = sd
		s.mu.Unlock()
	}

	return err
}

// synced stores and synchronizes single mount. The main goal of synced logic
// is to make remote and local indexes similar.
type synced struct {
	opts *SyncOpts
	id   ID     // identifier of synced mount.
	m    Mount  // single mount with absolute paths.
	wd   string // working directory of the mount.

	ridx *index.Index // known state of remote index.
	lidx *index.Index // known state of local index.
}

// newSynced creates a new sync instance. It ensures basic mount directory
// structure. This function is blocking.
func newSynced(id ID, m Mount, opts *SyncOpts) (*synced, error) {
	s := &synced{
		opts: opts,
		id:   id,
		m:    m,
		wd:   filepath.Join(opts.WorkDir, "mount-"+string(id)),
	}

	// Create directory structure if it doesn't exist.
	if err := s.mktree(); err != nil {
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

	return s, nil
}

// mktree ensures that synced working directory is created.
func (s *synced) mktree() error {
	dataPath := filepath.Join(s.wd, "data")
	info, err := os.Stat(dataPath)
	if os.IsNotExist(err) {
		return os.MkdirAll(dataPath, 0755)
	}
	if err != nil {
		return err
	}

	if !info.IsDir() {
		return fmt.Errorf("file %s is not a directory", s.wd)
	}

	return nil
}

// loadIdx reads named index from synced working directory. If index file does
// not exist, it is fetched by calling provided `fetchIdx` function and saved to
// provided path.
func (s *synced) loadIdx(name string, fetchIdx idxFunc) (*index.Index, error) {
	path := filepath.Join(s.wd, name)
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
func (s *synced) fetchRemoteIdx() (*index.Index, error) {
	spv := client.NewSupervised(func() (client.Client, error) {
		return s.opts.ClientFunc(s.id)
	}, 30*time.Second)

	return spv.MountGetIndex(s.m.RemotePath)
}

// fetchLocalIdx always scans mount cache directory and creates new index.
func (s *synced) fetchLocalIdx() (*index.Index, error) {
	return index.NewIndexFiles(filepath.Join(s.wd, "data"))
}

// updateLocal updates local index and saves it to cache directory.
func (s *synced) updateLocal() error {
	dataPath := filepath.Join(s.wd, "data")
	cs := s.lidx.Compare(dataPath)

	if len(cs) == 0 {
		return nil
	}

	s.lidx.Apply(dataPath, cs)
	return index.SaveIndex(s.lidx, filepath.Join(s.wd, LocalIndexName))
}

// info returns the current status of synced indexes.
func (s *synced) info() *Info {
	return &Info{
		ID:           s.id,
		Mount:        s.m,
		SyncCount:    s.lidx.Count(-1),
		AllCount:     s.ridx.Count(-1),
		SyncDiskSize: s.lidx.DiskSize(-1),
		AllDiskSize:  s.ridx.DiskSize(-1),
	}
}

// Drop closes synced mount and cleans up all resources acquired by it.
func (s *synced) drop() error {
	return os.RemoveAll(s.wd)
}
