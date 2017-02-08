package syncs

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sync"

	"koding/klient/machine"
	"koding/klient/machine/client"
	"koding/klient/machine/mount"
	msync "koding/klient/machine/mount/sync"

	"github.com/koding/logging"
)

// SyncsOpts are the options used to configure Syncs object.
type SyncsOpts struct {
	// WorkDir is a working directory that will be used by Syncs object. The
	// directory structure for multiple mounts will look like:
	//
	//   WorkDir
	//   +-mount-<ID1>
	//     +-...
	//   +-mount-<ID2>
	//     +-...
	//   +-mount-<IDN>
	//     +-...
	//
	WorkDir string

	// Log is used for logging. If nil, default logger will be created.
	Log logging.Logger
}

// Valid checks if provided options are correct.
func (opts *SyncsOpts) Valid() error {
	if opts == nil {
		return errors.New("mount syncs options are nil")
	}

	if opts.WorkDir == "" {
		return errors.New("working directory is not set")
	}

	return nil
}

// Syncs is a set of mount syncs with single file synchronization pool. Each
// sync is binded to unique mount ID.
type Syncs struct {
	wd string

	log logging.Logger

	mu  sync.RWMutex
	scs map[mount.ID]*msync.Sync
}

// New creates a new Syncs instance from the given options.
func New(opts SyncsOpts) (*Syncs, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	if err := os.MkdirAll(opts.WorkDir, 0755); err != nil {
		return nil, err
	}

	s := &Syncs{
		wd:  opts.WorkDir,
		log: opts.Log,
		scs: make(map[mount.ID]*msync.Sync),
	}

	if s.log == nil {
		s.log = machine.DefaultLogger
	}

	return s, nil
}

// Add starts synchronization between remote and local directories. It creates
// all necessary cache files if they are not present.
func (s *Syncs) Add(mountID mount.ID, m mount.Mount, dynClient client.DynamicClientFunc) error {
	s.mu.RLock()
	_, ok := s.scs[mountID]
	s.mu.RUnlock()

	if ok {
		return fmt.Errorf("sync for mount with ID %s already exists", mountID)
	}

	sc, err := msync.NewSync(mountID, m, msync.SyncOpts{
		ClientFunc: dynClient,
		WorkDir:    filepath.Join(s.wd, "mount-"+string(mountID)),
		Log:        s.log.New(string(mountID)),
	})
	if err != nil {
		return err
	}

	s.mu.Lock()
	if _, ok := s.scs[mountID]; ok {
		s.mu.Unlock()
		return fmt.Errorf("sync for mount with ID %s added twice", mountID)
	}
	s.scs[mountID] = sc
	s.mu.Unlock()

	return nil
}

// Info returns the current state of mount synchronization with provided ID.
func (s *Syncs) Info(mountID mount.ID) (*msync.Info, error) {
	s.mu.RLock()
	sc, ok := s.scs[mountID]
	s.mu.RUnlock()

	if !ok {
		return nil, mount.ErrMountNotFound
	}

	return sc.Info(), nil
}

// Drop removes the mount sync and cleans the resources it uses.
func (s *Syncs) Drop(mountID mount.ID) (err error) {
	s.mu.Lock()
	sc, ok := s.scs[mountID]
	delete(s.scs, mountID)
	s.mu.Unlock()

	if !ok {
		return nil
	}

	if err = sc.Drop(); err != nil {
		// Drop failed - put sync back to the map.
		s.mu.Lock()
		s.scs[mountID] = sc
		s.mu.Unlock()
	}

	return err
}

// Close closes and removes all stored syncs.
func (s *Syncs) Close() {
	s.mu.Lock()
	defer s.mu.Unlock()

	for mountID, sc := range s.scs {
		sc.Close()
		delete(s.scs, mountID)
	}
}
