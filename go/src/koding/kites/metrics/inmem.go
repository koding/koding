package metrics

import "sync"

type inmem struct {
	db [][]byte
	mu sync.Mutex
}

func newInMemStorage() Storage {
	return &inmem{
		db: make([][]byte, 0),
	}
}

// Write appends incoming data inmem storage
func (i *inmem) Write(d []byte) (int, error) {
	i.mu.Lock()
	i.db = append(i.db, d)
	i.mu.Unlock()
	return len(d), nil
}

// ConsumeN reads first n records from boltdb and deletes them permanently if
// OperatorFunc run successfully.
//
// If n < 0 process all the records available.
// If n == 0 this call is noop.
// If n > 0 process up to n available records.
func (i *inmem) ConsumeN(n int, f OperatorFunc) (int, error) {
	if n < 0 || n > len(i.db) {
		n = len(i.db)
	}

	if n < 1 {
		return 0, nil
	}

	i.mu.Lock()
	defer i.mu.Unlock()

	res := make([][]byte, n, n)
	copy(res, i.db[:n])
	if err := f(res); err != nil {
		return 0, err
	}

	i.db = i.db[n:]
	return len(res), nil
}

// Close closes the underlying storage
func (*inmem) Close() error { return nil }
