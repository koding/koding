package syncs

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"sync"

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
var debugAll = os.Getenv("KD_DEBUG_MOUNT") != ""

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

	// NotifyBuilder defines a factory used to build FS notification objects.
	NotifyBuilder notify.Builder

	// SyncBuilder defines a factory used to build file synchronization objects.
	SyncBuilder msync.Builder

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
	if opts.NotifyBuilder == nil {
		return errors.New("file system notification builder is nil")
	}
	if opts.SyncBuilder == nil {
		return errors.New("synchronization builder is nil")
	}

	return nil
}

// Syncs is a set of mount syncs with single file synchronization pool. Each
// sync is binded to unique mount ID.
type Syncs struct {
	wd string

	nb  notify.Builder
	sb  msync.Builder
	log logging.Logger

	once   sync.Once
	wg     sync.WaitGroup    // wait for workers and streams to stop.
	exC    chan msync.Execer // channel for synchronization jobs.
	closed bool              // set to true when syncs was closed.
	stopC  chan struct{}     // channel used to close any opened exec streams.

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
		nb:  opts.NotifyBuilder,
		sb:  opts.SyncBuilder,
		log: opts.Log,

		exC:   make(chan msync.Execer),
		stopC: make(chan struct{}),

		scs: make(map[mount.ID]*msync.Sync),
	}

	if s.log == nil {
		s.log = machine.DefaultLogger
	}

	// Start synchronization workers.
	for i := 0; i < 2*runtime.NumCPU(); i++ {
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

// Add starts synchronization between remote and local directories. It creates
// all necessary cache files if they are not present.
func (s *Syncs) Add(mountID mount.ID, m mount.Mount,
	dynAddr client.DynamicAddrFunc, dynClient client.DynamicClientFunc) error {
	s.mu.RLock()
	if s.closed {
		s.mu.RUnlock()
		return fmt.Errorf("syncs is closed")
	}
	_, ok := s.scs[mountID]
	s.mu.RUnlock()

	if ok {
		return fmt.Errorf("sync for mount with ID %s already exists", mountID)
	}

	sc, err := msync.NewSync(mountID, m, msync.SyncOpts{
		AddrFunc:      dynAddr,
		ClientFunc:    dynClient,
		WorkDir:       filepath.Join(s.wd, "mount-"+string(mountID)),
		NotifyBuilder: s.nb,
		SyncBuilder:   s.sb,
		Log:           s.log.New(string(mountID)),
	})
	if err != nil {
		return err
	}

	s.mu.Lock()
	if _, ok := s.scs[mountID]; ok {
		s.mu.Unlock()
		sc.Close()
		return fmt.Errorf("sync for mount with ID %s added twice", mountID)
	}
	s.scs[mountID] = sc
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
