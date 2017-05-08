package syncs

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sync"

	"koding/klient/config"
	"koding/klient/machine"
	"koding/klient/machine/client"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/notify"
	msync "koding/klient/machine/mount/sync"

	"github.com/koding/logging"
)

// debugAll must be set in order to debug print all synced events. Worker
// events may produce a lot of events so we keep logging disabled even in
// "normal" debug mode.
var debugAll = os.Getenv("KD_DEBUG_MOUNT") != "" || config.Konfig.Mount.Debug >= 1

// Options are the options used to configure Syncs object.
type Options struct {
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
func (opts *Options) Valid() error {
	if opts == nil {
		return errors.New("mount syncs options are nil")
	}
	if opts.WorkDir == "" {
		return errors.New("working directory is not set")
	}

	return nil
}

// Syncs is a set of mount syncs with single file synchronization pool. Each
// sync is bound to unique mount ID.
type Syncs struct {
	wd  string
	log logging.Logger

	once   sync.Once
	wg     sync.WaitGroup    // wait for workers and streams to stop.
	exC    chan msync.Execer // channel for synchronization jobs.
	closed bool              // set to true when syncs was closed.
	stopC  chan struct{}     // channel used to close any opened exec streams.

	mu  sync.RWMutex
	scs map[mount.ID]*mount.Sync
}

// New creates a new Syncs instance from the given options.
func New(opts Options) (*Syncs, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	s := &Syncs{
		wd:  opts.WorkDir,
		log: opts.Log,

		exC:   make(chan msync.Execer),
		stopC: make(chan struct{}),

		scs: make(map[mount.ID]*mount.Sync),
	}

	if s.log == nil {
		s.log = machine.DefaultLogger
	}

	// Start synchronization workers.
	for i := 0; i < config.Konfig.Mount.Sync.Workers; i++ {
		s.wg.Add(1)
		go s.worker()
	}

	return s, nil
}

// worker consumes and executes synchronization events from all stored mounts.
func (s *Syncs) worker() {
	defer s.wg.Done()

	for {
		select {
		case ex := <-s.exC:
			if ex == nil {
				continue
			}

			if err := ex.Exec(); err != nil || debugAll {
				s.log.Debug("%s: %v", ex, err)
			}
		case <-s.stopC:
			return
		}
	}
}

// AddRequest contains data needed to call Syncs.Add method.
type AddRequest struct {
	// MountID is a unique ID of the mount in UUIDv4 format.
	MountID mount.ID

	// Mount stores mount paths.
	Mount mount.Mount

	// NotifyBuilder defines a factory used to build file system notification
	// objects.
	NotifyBuilder notify.Builder

	// SyncBuilder defines a factory used to build object which will be
	// responsible for syncing files.
	SyncBuilder msync.Builder

	// ClientFunc is a factory for dynamic clients.
	ClientFunc client.DynamicClientFunc

	// SSHFunc is a factory for client SSH addresses.
	SSHFunc msync.DynamicSSHFunc
}

// Valid validates add reqest data.
func (req *AddRequest) Valid() error {
	if req == nil {
		return errors.New("sync add request is nil")
	}

	if req.MountID == "" {
		return errors.New("mount ID cannot be empty")
	}
	if req.Mount.RemotePath == "" {
		return errors.New("mount remote path cannot be empty")
	}
	if req.NotifyBuilder == nil {
		return errors.New("notification builder cannot be nil")
	}
	if req.SyncBuilder == nil {
		return errors.New("synchronization builder cannot be nil")
	}
	if req.ClientFunc == nil {
		return errors.New("dynamic client function cannot be nil")
	}
	if req.SSHFunc == nil {
		return errors.New("dynamic SSH address function cannot be nil")
	}

	return nil
}

// Add starts synchronization between remote and local directories. It creates
// all necessary cache files if they are not present.
func (s *Syncs) Add(req *AddRequest) error {
	if err := req.Valid(); err != nil {
		return err
	}

	s.mu.RLock()
	if s.closed {
		s.mu.RUnlock()
		return fmt.Errorf("syncs is closed")
	}
	_, ok := s.scs[req.MountID]
	s.mu.RUnlock()

	if ok {
		return fmt.Errorf("sync for mount with ID %s already exists", req.MountID)
	}

	sc, err := mount.NewSync(req.MountID, req.Mount, mount.Options{
		ClientFunc:    req.ClientFunc,
		SSHFunc:       req.SSHFunc,
		WorkDir:       filepath.Join(s.wd, "mount-"+string(req.MountID)),
		NotifyBuilder: req.NotifyBuilder,
		SyncBuilder:   req.SyncBuilder,
		Log:           s.log.New(string(req.MountID)),
	})
	if err != nil {
		return err
	}

	s.mu.Lock()
	if _, ok := s.scs[req.MountID]; ok {
		s.mu.Unlock()
		sc.Close()
		return fmt.Errorf("sync for mount with ID %s added twice", req.MountID)
	}
	s.scs[req.MountID] = sc
	s.mu.Unlock()

	// proxy synchronization events to workers pool.
	s.wg.Add(1)
	go s.sink(sc.Stream())

	return nil
}

// sink routes synchronization from a single mount to execution workers.
func (s *Syncs) sink(exC <-chan msync.Execer) {
	defer s.wg.Done()

	for {
		select {
		case ex, ok := <-exC:
			if !ok {
				return
			}
			select {
			case s.exC <- ex:
			case <-s.stopC:
				return
			}
		case <-s.stopC:
			return
		}
	}
}

// Sync returns mount syncer that synchronizes mount with provided ID.
func (s *Syncs) Sync(mountID mount.ID) (*mount.Sync, error) {
	s.mu.RLock()
	sc, ok := s.scs[mountID]
	s.mu.RUnlock()

	if !ok {
		return nil, mount.ErrMountNotFound
	}

	return sc, nil
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
func (s *Syncs) Close() error {
	s.once.Do(func() {
		s.mu.Lock()
		s.closed = true
		for mountID, sc := range s.scs {
			sc.Close()
			delete(s.scs, mountID)
		}
		s.mu.Unlock()

		close(s.stopC)
		s.wg.Wait()
	})

	return nil
}
