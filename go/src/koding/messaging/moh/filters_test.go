package moh

import (
	"log"
	"testing"
)

func TestFilters(t *testing.T) {
	filters := make(Filters)
	conn := &connection{}

	log.Println(filters)
	log.Println(conn.keys)

	filters.Add("a", conn)
	log.Println(filters)
	log.Println(conn.keys)

	// Check maps are updated
	if len(filters) != 1 {
		t.Error()
	}
	if len(filters["a"]) != 1 {
		t.Error()
	}

	// Check conn.keys is updated
	if len(conn.keys) != 1 {
		t.Error()
	}
	if conn.keys[0] != "a" {
		t.Error()
	}

	filters.Remove(conn)
	log.Println(filters)
	log.Println(conn.keys)

	// Check map is empty now
	if len(filters) != 0 {
		t.Error()
	}

	// Check key is removed from conn.keys
	if len(conn.keys) != 0 {
		t.Error()
	}
}
