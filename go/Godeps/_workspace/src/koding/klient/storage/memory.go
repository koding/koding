package storage

import "sync"

func NewMemoryStorage() *memoryStorage {
	return &memoryStorage{
		storage: make(map[string]string),
	}
}

// memoryStorage satisfies Storage interface
type memoryStorage struct {
	storage map[string]string
	sync.Mutex
}

func (m *memoryStorage) Get(key string) (string, error) {
	m.Lock()
	defer m.Unlock()

	value, ok := m.storage[key]
	if !ok {
		return "", ErrKeyNotFound
	}

	return value, nil
}

func (m *memoryStorage) Set(key, value string) error {
	m.Lock()
	m.storage[key] = value
	m.Unlock()

	return nil
}

func (m *memoryStorage) Delete(key string) error {
	m.Lock()
	delete(m.storage, key)
	m.Unlock()

	return nil
}
