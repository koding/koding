package moh

// Filters is a type used for managing the message subscription keys of subscribers.
// Methods also updates the keys field of the connections.
// Keep in mind that it's methods are not thread-safe.
type Filters map[string]map[*connection]bool

// Add adds the connection to the list for key.
// Also adds the key to the keys field of the conn.
func (f Filters) Add(key string, conn *connection) {
	connections := f[key]
	if connections == nil {
		f[key] = make(map[*connection]bool)
	}
	f[key][conn] = true
	conn.keys = append(conn.keys, key)
}

// Remove removes the connection from the map for all of it's keys.
func (f Filters) Remove(conn *connection) {
	for _, key := range conn.keys {
		f.removeSingle(key, conn)
	}
	conn.keys = make([]string, 0)
}

func (f Filters) removeSingle(key string, conn *connection) {
	connections := f[key]
	delete(connections, conn)
	if len(connections) == 0 {
		delete(f, key)
	}
}
