package aliases_test

import (
	"testing"

	"koding/klient/machine"
	"koding/klient/machine/machinegroup/aliases"
)

func TestAliasesCreate(t *testing.T) {
	const wantAliases = 500
	m := make(map[string]struct{})

	as := aliases.New()
	for i := 0; i < wantAliases; i++ {
		alias, err := as.Create(machine.ID(i))
		if err != nil {
			t.Fatalf("want err = nil; got %v", err)
		}
		m[alias] = struct{}{}

		// Second creation for the same ID should be no-op.
		alias, err = as.Create(machine.ID(i))
		if err != nil {
			t.Fatalf("want err = nil; got %v", err)
		}
		m[alias] = struct{}{}
	}

	if len(m) != wantAliases {
		t.Fatalf("want %d aliases; got %d", wantAliases, len(m))
	}
}

func TestAliasesMachineID(t *testing.T) {
	m := map[machine.ID]string{
		"ID_1": "blue_banana",
		"ID_2": "red_orange1",
		"ID_3": "white_mango",
		"ID_4": "black_tomato2",
		"ID_5": "silver_kiwi",
	}

	as := aliases.New()
	for id, alias := range m {
		if err := as.Add(id, alias); err != nil {
			t.Fatalf("want err = nil; got %v", err)
		}
	}

	tests := map[string]struct {
		Alias    string
		Expected machine.ID
		NotFound bool
	}{
		"full alias": {
			Alias:    "white_mango",
			Expected: machine.ID("ID_3"),
			NotFound: false,
		},
		"machine id": {
			Alias:    "ID_5",
			Expected: machine.ID("ID_5"),
			NotFound: false,
		},
		"unknown": {
			Alias:    "green_kiwi",
			Expected: machine.ID(""),
			NotFound: true,
		},
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			id, err := as.MachineID(test.Alias)
			if (err == machine.ErrMachineNotFound) != test.NotFound {
				t.Fatalf("want err machine not found = %t; got %v", test.NotFound, err)
			}

			if id != test.Expected {
				t.Fatalf("want id = %v; got %v", test.Expected, id)
			}
		})
	}
}
