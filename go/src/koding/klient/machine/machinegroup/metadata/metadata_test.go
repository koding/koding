package metadata_test

import (
	"reflect"
	"testing"

	"koding/klient/machine"
	"koding/klient/machine/machinegroup/metadata"
)

func TestMetadataMachineID(t *testing.T) {
	m := map[machine.ID]*machine.Metadata{
		"ID_1": &machine.Metadata{
			Owner: "",
			Label: "machineA",
		},
		"ID_2": &machine.Metadata{
			Owner: "user",
			Label: "machineA",
		},
		"ID_3": &machine.Metadata{
			Owner: "",
			Label: "machineA",
		},
		"ID_4": &machine.Metadata{
			Owner: "",
			Label: "machineB",
		},
		"ID_5": &machine.Metadata{
			Owner: "",
			Label: "machineC",
		},
	}

	meta := metadata.New()
	for id, entry := range m {
		if err := meta.Add(id, entry); err != nil {
			t.Fatalf("want err = nil; got %v", err)
		}
	}

	tests := map[string]struct {
		Owner    string
		Label    string
		Expected machine.IDSlice
		NotFound bool
	}{
		"full meta": {
			Owner:    "user",
			Label:    "machineA",
			Expected: machine.IDSlice{"ID_2"},
			NotFound: false,
		},
		"two machines": {
			Owner:    "",
			Label:    "machineA",
			Expected: machine.IDSlice{"ID_1", "ID_3"},
			NotFound: false,
		},
		"empty owner": {
			Owner:    "",
			Label:    "machineC",
			Expected: machine.IDSlice{"ID_5"},
			NotFound: false,
		},
		"non existing machine": {
			Owner:    "unknown",
			Label:    "machineA",
			Expected: nil,
			NotFound: true,
		},
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			ids, err := meta.MachineID(test.Owner, test.Label)
			if (err == machine.ErrMachineNotFound) != test.NotFound {
				t.Fatalf("want err machine not found = %t; got %v", test.NotFound, err)
			}

			if !reflect.DeepEqual(ids, test.Expected) {
				t.Fatalf("want ids = %v; got %v", test.Expected, ids)
			}
		})
	}
}
