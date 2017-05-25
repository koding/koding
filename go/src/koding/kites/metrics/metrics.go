package metrics

import (
	"context"
	"path/filepath"

	kitesconfig "koding/kites/config"

	statsd "github.com/DataDog/datadog-go/statsd"
	"github.com/boltdb/bolt"
)

// Metrics wraps metric
type Metrics struct {
	storage Storage
	Datadog *statsd.Client
}

// New creates new metrics collector.
//
// It will try to store the metrics in best available storage. First will try
// storing in BoltDb but if opening fails, will fallback to in memory storage.
func New(app string) (*Metrics, error) {
	boltPath := filepath.Join(kitesconfig.KodingHome(), "metrics.bolt")

	return NewWithPath(boltPath, app)
}

// NewWithPath creates new metrics collector with storing data to given path.
// See New func.
func NewWithPath(boltPath, app string) (*Metrics, error) {
	var storage Storage
	var err error
	storage, err = NewBoltStorage(boltPath)
	if err != nil {
		storage = newInMemStorage()
	}

	return NewWithStorage(storage, app)
}

// NewWithDB creates a new metric collector with given bolt db instance. See New
// func.
func NewWithDB(db *bolt.DB, app string) (*Metrics, error) {
	var storage Storage
	var err error
	if db != nil {
		storage, err = NewBoltStorageWithDB(db)
	}

	if err != nil {
		storage = newInMemStorage()
	}

	return NewWithStorage(storage, app)
}

// NewWithStorage creates a new metric collector with given bolt storage.
func NewWithStorage(q Storage, app string) (*Metrics, error) {
	dd, err := statsd.NewWithConn(q)
	if err != nil {
		return nil, err
	}

	dd.Namespace = app + "_"
	return &Metrics{
		storage: q,
		Datadog: dd,
	}, nil
}

// Process gets the records and deletes them after operation.
func (m *Metrics) Process(f OperatorFunc) error {
	_, err := m.storage.ConsumeN(-1, f)
	return err
}

// ProcessContext gets the records and deletes them after operation.
func (m *Metrics) ProcessContext(ctx context.Context, n int, f OperatorFunc) error {
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
			processedCount, err := m.storage.ConsumeN(n, f)
			if err != nil {
				return err
			}

			// we consumed enough.
			if processedCount != n {
				return nil
			}
		}
	}
}

// Close closes the underlying connections if any.
func (m *Metrics) Close() error {
	if m == nil {
		return nil
	}

	if m.storage != nil {
		return m.storage.Close()
	}

	return nil
}
