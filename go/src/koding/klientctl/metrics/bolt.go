package metrics

import (
	"io"
	"strconv"
	"time"

	"github.com/boltdb/bolt"
)

var _ io.WriteCloser = &BoltConn{}

// BoltConn writes and reads to BoltDB
type BoltConn struct {
	db         *bolt.DB
	bucketName []byte
}

// NewBoltConn implements Writer and Closer interfaces.
func NewBoltConn(path, bucket string) (*BoltConn, error) {
	options := &bolt.Options{
		Timeout: 5 * time.Second,
	}

	db, err := bolt.Open(path, 0644, options)
	if err != nil {
		return nil, err
	}

	if err := db.Update(func(tx *bolt.Tx) error {
		_, err := tx.CreateBucketIfNotExists([]byte(bucket))
		return err
	}); err != nil {
		return nil, err
	}

	return &BoltConn{
		db:         db,
		bucketName: []byte(bucket),
	}, nil
}

// Write writes incoming data to boltdb
func (b *BoltConn) Write(d []byte) (n int, err error) {
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
func (b *BoltConn) Close() error {
	return b.db.Close()
}

// ReadN reads n records from boltdb and deletes them permanently if run successfully.
func (b *BoltConn) ReadN(n int) ([][]byte, error) {
	res := make([][]byte, 0, n)
	if err := b.db.Update(func(tx *bolt.Tx) error {
		c := tx.Bucket(b.bucketName).Cursor()

		for k, v := c.First(); k != nil && n > 0; k, v = c.Next() {
			res = append(res, v)
			// clean up after ourselves.
			if err := c.Delete(); err != nil {
				return err
			}
			n--
		}

		return nil
	}); err != nil {
		return nil, err
	}

	return res, nil
}
