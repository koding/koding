package metrics

import (
	"context"
	"path/filepath"

	kitesconfig "koding/kites/config"

	statsd "github.com/DataDog/datadog-go/statsd"
)

// Metrics wraps metric
type Metrics struct {
	bolt    *BoltQueue
	Datadog *statsd.Client
}

// New creates new metrics collector.
func New() (*Metrics, error) {
	boltPath := filepath.Join(kitesconfig.KodingHome(), "metrics.bolt")

	return NewWithPath(boltPath)
}

// NewWithPath creates new metrics collector with storing data to given path.
func NewWithPath(boltPath string) (*Metrics, error) {
	boltConn, err := NewBoltQueue(boltPath)
	if err != nil {
		return nil, err
	}

	dd, err := statsd.NewWithConn(boltConn)
	if err != nil {
		return nil, err
	}

	return &Metrics{
		bolt:    boltConn,
		Datadog: dd,
	}, nil
}

// Process gets the records and deletes them after operation.
func (m *Metrics) Process(f OperatorFunc) error {
	_, err := m.bolt.ConsumeN(-1, f)
	return err
}

// ProcessContext gets the records and deletes them after operation.
func (m *Metrics) ProcessContext(ctx context.Context, n int, f OperatorFunc) error {
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
			processedCount, err := m.bolt.ConsumeN(n, f)
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
	if m.bolt != nil {
		return m.bolt.Close()
	}

	return nil
}
