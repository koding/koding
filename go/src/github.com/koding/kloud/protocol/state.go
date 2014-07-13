package protocol

import "sync"

type Storage interface {
	// Get returns the value from the Storage for the given key. Value is empty
	// if the the key is not available.
	Get(key string) (value interface{})

	// Put puts the given string
	Put(key string, value interface{})
}

type MapStorage struct {
	sync.Mutex
	sync.Once
	m map[string]interface{}
}

func NewMapStorage() *MapStorage {
	return &MapStorage{
		m: make(map[string]interface{}),
	}
}

func (m *MapStorage) Get(key string) interface{} {
	m.Lock()
	defer m.Unlock()

	return m.m[key]
}

func (m *MapStorage) Put(key string, value interface{}) {
	m.Lock()
	defer m.Unlock()

	m.m[key] = value
}
