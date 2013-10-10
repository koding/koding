package moh

// Filters is a type used for managing the message subscription keys of subscribers.
// Methods also updates the keys field of the connections.
// Keep in mind that it's methods are not thread-safe.
type Filters map[string]map[*connection]bool

// Add adds the connection to the list for key.
// Also adds the key to the keys field of the conn.
func (f Filters) Add(conn *connection, key string) {
	connections := f[key]
	if connections == nil {
		f[key] = make(map[*connection]bool)
	}
	f[key][conn] = true
	conn.keys[key] = true
}

// Remove removes the connection from a key in filters.
func (f Filters) Remove(conn *connection, key string) {
	connections := f[key]
	delete(conn.keys, key)
	delete(connections, conn)
	if len(connections) == 0 {
		delete(f, key)
	}
}

// Remove removes the connection from the map for all of it's keys.
func (f Filters) RemoveAll(conn *connection) {
	for key := range conn.keys {
		f.Remove(conn, key)
	}
}
