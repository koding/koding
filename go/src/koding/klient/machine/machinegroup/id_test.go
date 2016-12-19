package machinegroup

import (
	"testing"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/machinetest"
)

func TestID(t *testing.T) {
	var (
		idA = machine.ID("servA")
		idB = machine.ID("servB")

		ipA = machine.Addr{Network: "ip", Value: "52.24.123.32", UpdatedAt: time.Now()}
		ipB = machine.Addr{Network: "ip", Value: "10.0.1.16", UpdatedAt: time.Now()}
	)

	g, err := New(testOptions(machinetest.NewNilBuilder()))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	req := &CreateRequest{
		Addresses: map[machine.ID][]machine.Addr{
			idA: {ipA},
			idB: {ipB},
		},
	}

	res, err := g.Create(req)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	tests := map[string]struct {
		Identifier string
		ID         machine.ID
		Found      bool
	}{
		"by ID": {
			Identifier: string(idA),
			ID:         idA,
			Found:      true,
		},
		"by alias": {
			Identifier: res.Aliases[idB],
			ID:         idB,
			Found:      true,
		},
		"by IP": {
			Identifier: ipA.Value,
			ID:         idA,
			Found:      true,
		},
		"not found alias": {
			Identifier: "unknown_alias",
			ID:         "",
			Found:      false,
		},
		"not found IP": {
			Identifier: "127.0.0.12",
			ID:         "",
			Found:      false,
		},
		"not found TCP": {
			Identifier: ipB.Value + ":8080",
			ID:         "",
			Found:      false,
		},
	}

	for name, test := range tests {
		test := test // capture range variable.
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			req := &IDRequest{
				Identifier: test.Identifier,
			}

			res, err := g.ID(req)
			if (err == nil) != test.Found {
				t.Fatalf("want (err == nil) = %t; got err: %v", test.Found, err)
			}

			if !test.Found {
				return
			}

			if res.ID != test.ID {
				t.Fatalf("want ID = %v; got %v", test.ID, res.ID)
			}
		})
	}
}
