package supervisors

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

// SupervisorsOpts are the options used to configure Supervisors object.
type SupervisorsOpts struct {
	// WorkDir is a working directory that will be used by Supervisors object.
	// The directory structure for multiple mounts will look like:
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
func (opts *SupervisorsOpts) Valid() error {
	if opts == nil {
		return errors.New("mount supervisors options are nil")
	}

	if opts.WorkDir == "" {
		return errors.New("working directory is not set")
	}

	return nil
}

// Supervisors is a set of mount supervisors with single file synchronization
// pool. Each supervisor is binded to unique mount ID.
type Supervisors struct {
	wd string

	log logging.Logger

	mu   sync.RWMutex
	spvs map[mount.ID]*msync.Supervisor
}

// New creates a new Supervisors instance from the given options.
func New(opts SupervisorsOpts) (*Supervisors, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	if err := os.MkdirAll(opts.WorkDir, 0755); err != nil {
		return nil, err
	}

	s := &Supervisors{
		wd:   opts.WorkDir,
		log:  opts.Log,
		spvs: make(map[mount.ID]*msync.Supervisor),
	}

	if s.log == nil {
		s.log = machine.DefaultLogger
	}

	return s, nil
}

// Add starts synchronization between remote and local directories. It creates
// all necessary cache files if they are not present.
func (s *Supervisors) Add(mountID mount.ID, m mount.Mount, dynClient client.DynamicClientFunc) error {
	s.mu.RLock()
	_, ok := s.spvs[mountID]
	s.mu.RUnlock()

	if ok {
		return fmt.Errorf("supervisor for mount with ID %s already exists", mountID)
	}

	spv, err := msync.NewSupervisor(mountID, m, msync.SupervisorOpts{
		ClientFunc: dynClient,
		WorkDir:    filepath.Join(s.wd, "mount-"+string(mountID)),
		Log:        s.log.New(string(mountID)),
	})
	if err != nil {
		return err
	}

	s.mu.Lock()
	if _, ok := s.spvs[mountID]; ok {
		s.mu.Unlock()
		return fmt.Errorf("supervisor for mount with ID %s added twice", mountID)
	}
	s.spvs[mountID] = spv
	s.mu.Unlock()

	return nil
}

// Info returns the current state of mount supervisor with provided ID.
func (s *Supervisors) Info(mountID mount.ID) (*msync.Info, error) {
	s.mu.RLock()
	spv, ok := s.spvs[mountID]
	s.mu.RUnlock()

	if !ok {
		return nil, mount.ErrMountNotFound
	}

	return spv.Info(), nil
}

// Drop removes the mount supervisor and cleans the resources it uses.
func (s *Supervisors) Drop(mountID mount.ID) (err error) {
	s.mu.Lock()
	spv, ok := s.spvs[mountID]
	delete(s.spvs, mountID)
	s.mu.Unlock()

	if !ok {
		return nil
	}

	if err = spv.Drop(); err != nil {
		// Drop failed - put supervisor back to the map.
		s.mu.Lock()
		s.spvs[mountID] = spv
		s.mu.Unlock()
	}

	return err
}

// Close closes and removes all stored supervisors.
func (s *Supervisors) Close() {
	s.mu.Lock()
	defer s.mu.Unlock()

	for mountID, spv := range s.spvs {
		spv.Close()
		delete(s.spvs, mountID)
	}
}
