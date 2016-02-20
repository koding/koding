package vagrant

import (
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strings"
	"sync"

	"github.com/boltdb/bolt"
	"github.com/koding/kite"
)

var (
	// dbBucket is the bucket name used to store vagrant machines and their
	// statuses
	dbBucket = []byte("vagrant")
)

// Machine represents a single vagrant machine that was built and provisioned
// by klient.
type Machine struct {
	Info *Info `json:"info"`
}

// Copy returns a copy of the machine value. Additionally it ensures
// the FilePath is all lower-case, as we assume the paths are
// case-insensitive for portability reasons.
func (m *Machine) Copy() *Machine {
	infoCopy := *m.Info
	infoCopy.FilePath = strings.ToLower(infoCopy.FilePath)
	mCopy := *m
	mCopy.Info = &infoCopy
	return &mCopy
}

// ErrMachineNotFound is returned by (Storage).Machine method when the
// underlying storage has no information recorded for a machine
// given by the (*Machine).Info.FilePath field.
var ErrNoMachineFound = errors.New("status not found")

// Storage is a database access interface for vagrant machines.
type Storage interface {
	Machines() ([]*Machine, error)
	Machine(filePath string) (*Machine, error)
	UpdateMachine(m *Machine) error
}

func newStorage(opts *Options) Storage {
	if opts.DB != nil {
		return &boltStorage{
			db:  opts.DB,
			log: opts.Log,
		}
	}
	return &memStorage{
		m:   make(map[string]*Machine),
		log: opts.Log,
	}
}

type boltStorage struct {
	db  *bolt.DB
	log kite.Logger
}

// Machines lists all machines built by klient.
func (bs *boltStorage) Machines() ([]*Machine, error) {
	var machines []*Machine
	err := bs.db.View(func(tx *bolt.Tx) error {
		b, err := bs.bucket(tx)
		if err != nil {
			return err
		}

		c := b.Cursor()

		for k, v := c.First(); k != nil; k, v = c.Next() {
			var m Machine
			if err := json.Unmarshal(v, &m); err != nil {
				return fmt.Errorf("unable to read %q: %s", k, err)
			}

			machines = append(machines, &m)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	if len(machines) == 0 {
		return nil, ErrNoMachineFound
	}

	sort.Sort(machinesByPath(machines))

	return machines, nil
}

// Machine looks up a machine by the given filePath.
func (bs *boltStorage) Machine(filePath string) (*Machine, error) {
	var m Machine
	err := bs.db.View(func(tx *bolt.Tx) error {
		b, err := bs.bucket(tx)
		if err != nil {
			return err
		}

		v := b.Get([]byte(filePath))
		if v == nil {
			return ErrNoMachineFound
		}

		return json.Unmarshal(v, &m)
	})
	if err != nil {
		return nil, err
	}

	return &m, nil
}

// UpdateMachine replaces the machine document under m.Info.FilePath,
// overwritting previous value if it exists.
func (bs *boltStorage) UpdateMachine(m *Machine) error {
	return bs.db.Update(func(tx *bolt.Tx) error {
		b, err := bs.bucket(tx)
		if err != nil {
			return err
		}

		mCopy := m.Copy()

		v, err := json.Marshal(mCopy)
		if err != nil {
			return err
		}

		return b.Put([]byte(mCopy.Info.FilePath), v)
	})
}

func (bs *boltStorage) bucket(tx *bolt.Tx) (b *bolt.Bucket, err error) {
	b = tx.Bucket(dbBucket)
	if b == nil {
		b, err = tx.CreateBucketIfNotExists(dbBucket)
	}
	return b, err
}

type memStorage struct {
	m   map[string]*Machine
	mu  sync.RWMutex
	log kite.Logger
}

// Machine list the machines we know off. Sorted by (*Machine).Info.FilePath.
func (ms *memStorage) Machines() ([]*Machine, error) {
	ms.mu.RLock()
	var machines []*Machine
	for _, m := range ms.m {
		machines = append(machines, m)
	}
	ms.mu.RUnlock()

	if len(machines) == 0 {
		return nil, ErrNoMachineFound
	}

	sort.Sort(machinesByPath(machines))

	return machines, nil
}

// Machine looks up a machine by the given filePath.
func (ms *memStorage) Machine(filePath string) (*Machine, error) {
	ms.mu.RLock()
	machine, ok := ms.m[strings.ToLower(filePath)]
	ms.mu.RUnlock()

	if !ok {
		return nil, ErrNoMachineFound
	}

	return machine, nil
}

// UpdateMachine replaces a machine document with the given m.
func (ms *memStorage) UpdateMachine(m *Machine) error {
	mCopy := m.Copy()

	ms.mu.Lock()
	ms.m[mCopy.Info.FilePath] = mCopy
	ms.mu.Unlock()

	return nil
}

// machinesByPath sorts slice of machines by filePath in ascending order.
type machinesByPath []*Machine

func (m machinesByPath) Len() int           { return len(m) }
func (m machinesByPath) Less(i, j int) bool { return m[i].Info.FilePath < m[j].Info.FilePath }
func (m machinesByPath) Swap(i, j int)      { m[i], m[j] = m[j], m[i] }
