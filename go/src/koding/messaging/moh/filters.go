package moh

import (
	"sync"
)

// Filters is a type used for managing the message subscription keys of subscribers.
// Methods also updates the keys field of the connections.
// Keep in mind that it's methods are not thread-safe.
type Filters struct {
	m map[string]map[*connection]bool
	sync.RWMutex
}

func NewFilters() *Filters {
	return &Filters{m: make(map[string]map[*connection]bool)}
}

func (f Filters) Get(key string) map[*connection]bool {
	f.RLock()
	defer f.RUnlock()

	return f.m[key]
}

// Add adds the connection to the list for key.
// Also adds the key to the keys field of the conn.
func (f Filters) Add(conn *connection, key string) {
	f.Lock()
	defer f.Unlock()

	connections := f.m[key]
	if connections == nil {
		f.m[key] = make(map[*connection]bool)
	}
	f.m[key][conn] = true
	conn.keys[key] = true
}

// Remove removes the connection from a key in filters.
func (f Filters) Remove(conn *connection, key string) {
	f.Lock()
	defer f.Unlock()

	connections := f.m[key]
	delete(conn.keys, key)
	delete(connections, conn)
	if len(connections) == 0 {
		delete(f.m, key)
	}
}

// Remove removes the connection from the map for all of it's keys.
func (f Filters) RemoveAll(conn *connection) {
	for key := range conn.keys {
		f.Remove(conn, key)
	}
}
