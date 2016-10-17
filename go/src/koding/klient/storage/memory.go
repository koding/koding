package storage

import "sync"

// NewMemoryStorage gives new Memory value that implements
// the Interface intergace.
func NewMemoryStorage() *Memory {
	return &Memory{
		M: make(map[string]string),
	}
}

var _ Interface = (*Memory)(nil)

// Memory satisfies Storage interface storing elements in memory.
//
// All operations on Memory storage are thread-safe.
type Memory struct {
	sync.RWMutex

	M map[string]string
}

// Get implements the Interface interface.
func (m *Memory) Get(key string) (string, error) {
	m.RLock()
	v, ok := m.M[key]
	m.RUnlock()

	if !ok {
		return "", ErrKeyNotFound
	}

	return v, nil
}

// Set implements the Interface interface.
func (m *Memory) Set(key, value string) error {
	m.Lock()
	m.M[key] = value
	m.Unlock()

	return nil
}

// Delete implements the Interface interface.
func (m *Memory) Delete(key string) error {
	m.Lock()
	delete(m.M, key)
	m.Unlock()

	return nil
}

// Close implements the Interface interface.
func (*Memory) Close() error {
	return nil
}
