package util_test

import (
	"testing"

	"koding/tools/util"
)

func TestRoutes(t *testing.T) {
	r, err := util.ParseRoutes()
	if err != nil {
		t.Fatal(err)
	}

	if len(r) == 0 {
		t.Fatal("no routes parsed")
	}

	for i, r := range r {
		t.Logf("[%d] routes: %s", i, r)
	}
}
