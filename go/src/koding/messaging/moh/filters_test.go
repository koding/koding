package moh

import (
	"log"
	"testing"
)

func TestFilters(t *testing.T) {
	filters := NewFilters()
	conn := &connection{keys: make(map[string]bool)}

	log.Println(filters)
	log.Println(conn.keys)

	filters.Add(conn, "a")
	log.Println(filters)
	log.Println(conn.keys)

	// Check maps are updated
	if len(filters.m) != 1 {
		t.Error()
	}
	if len(filters.Get("a")) != 1 {
		t.Error()
	}

	// Check conn.keys is updated
	if len(conn.keys) != 1 {
		t.Error()
	}
	if _, ok := conn.keys["a"]; !ok {
		t.Error()
	}

	filters.Remove(conn, "a")
	log.Println(filters)
	log.Println(conn.keys)

	// Check map is empty now
	if len(filters.m) != 0 {
		t.Error()
	}

	// Check key is removed from conn.keys
	if len(conn.keys) != 0 {
		t.Error()
	}
}
