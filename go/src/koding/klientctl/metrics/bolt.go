package metrics

import (
	"io"
	"strconv"
	"time"

	"github.com/boltdb/bolt"
)

const bucketName = "metrics"

var _ io.WriteCloser = &BoltQueue{}

// BoltQueue writes and reads to BoltDB
type BoltQueue struct {
	db         *bolt.DB
	bucketName []byte
}

// NewBoltQueue implements Writer and Closer interfaces.
func NewBoltQueue(path string) (*BoltQueue, error) {
	options := &bolt.Options{
		Timeout: 5 * time.Second,
	}

	db, err := bolt.Open(path, 0644, options)
	if err != nil {
		return nil, err
	}

	bucket := []byte(bucketName)

	if err := db.Update(func(tx *bolt.Tx) error {
		_, err := tx.CreateBucketIfNotExists(bucket)
		return err
	}); err != nil {
		return nil, err
	}

	return &BoltQueue{
		db:         db,
		bucketName: bucket,
	}, nil
}

// Write writes incoming data to boltdb
func (b *BoltQueue) Write(d []byte) (n int, err error) {
	// Start a write transaction.
	if err := b.db.Update(func(tx *bolt.Tx) error {
		bucket := tx.Bucket(b.bucketName)
		id, err := bucket.NextSequence()
		if err != nil {
			return err
		}
		return bucket.Put(
			[]byte(strconv.FormatInt(int64(id), 10)),
			d,
		)
	}); err != nil {
		return 0, err
	}

	return len(d), nil
}

// Close closes the underlying db connection
func (b *BoltQueue) Close() error {
	return b.db.Close()
}

// OperatorFunc is the contract for ForEach operations
type OperatorFunc func([][]byte) error

// ConsumeN reads first n records from boltdb and deletes them permanently if
// OperatorFunc run successfully.
// If n < 0 process all the records available.
// If n == 0 this call is noop.
// If n > 0 process up to n available records.
func (b *BoltQueue) ConsumeN(n int, f OperatorFunc) (int, error) {
	if n == 0 {
		return 0, nil
	}

	cap := n
	if n < 0 {
		cap = 0
	}

	res := make([][]byte, 0, cap)
	err := b.db.Update(func(tx *bolt.Tx) error {
		c := tx.Bucket(b.bucketName).Cursor()

		for k, v := c.First(); k != nil && n != 0; k, v = c.Next() {
			res = append(res, v)
			// clean up after ourselves.
			if err := c.Delete(); err != nil {
				return err
			}
			n--
		}
		return f(res)
	})

	if err != nil {
		return 0, err
	}

	return len(res), nil
}
