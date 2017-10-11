package machinegroup

import (
	"io/ioutil"
	"os"
	"testing"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/client/clienttest"
)

func TestID(t *testing.T) {
	var (
		idA = machine.ID("servA")
		idB = machine.ID("servB")

		ipA = machine.Addr{Network: "ip", Value: "52.24.123.32", UpdatedAt: time.Now()}
		ipB = machine.Addr{Network: "ip", Value: "10.0.1.16", UpdatedAt: time.Now()}

		metaA = machine.Metadata{
			Owner: "",
			Label: "machineA.0",
			Stack: "stackA",
			Team:  "teamA",
		}
		metaB = machine.Metadata{
			Owner: "root",
			Label: "machineB.1",
			Stack: "stackB",
			Team:  "teamB",
		}
	)

	wd, err := ioutil.TempDir("", "id")
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer os.RemoveAll(wd)

	g, err := New(testOptions(wd, clienttest.NewBuilder(nil)))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	req := &CreateRequest{
		Addresses: map[machine.ID][]machine.Addr{
			idA: {ipA},
			idB: {ipB},
		},
		Metadata: map[machine.ID]*machine.Metadata{
			idA: &metaA,
			idB: &metaB,
		},
	}

	res, err := g.Create(req)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	tests := map[string]struct {
		Identifier string
		IDs        machine.IDSlice
		Found      bool
	}{
		"by ID": {
			Identifier: string(idA),
			IDs:        machine.IDSlice{idA},
			Found:      true,
		},
		"by (at) ID": {
			Identifier: "@" + string(idA),
			IDs:        machine.IDSlice{idA},
			Found:      true,
		},
		"by alias": {
			Identifier: res.Aliases[idB],
			IDs:        machine.IDSlice{idB},
			Found:      true,
		},
		"by IP": {
			Identifier: ipA.Value,
			IDs:        machine.IDSlice{idA},
			Found:      true,
		},
		"by label": {
			Identifier: metaA.Label,
			IDs:        machine.IDSlice{idA},
			Found:      true,
		},
		"by (at) label": {
			Identifier: "@" + metaA.Label,
			IDs:        machine.IDSlice{idA},
			Found:      true,
		},
		"by userlabel": {
			Identifier: metaB.Owner + "@" + metaB.Label,
			IDs:        machine.IDSlice{idB},
			Found:      true,
		},
		"not found alias": {
			Identifier: "unknown_alias",
			IDs:        nil,
			Found:      false,
		},
		"not found IP": {
			Identifier: "127.0.0.12",
			IDs:        nil,
			Found:      false,
		},
		"not found TCP": {
			Identifier: ipB.Value + ":8080",
			IDs:        nil,
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

			if lr, lt := len(res.IDs), len(test.IDs); lr != lt {
				t.Fatalf("want response length == %d; got %d", lt, lr)
			}

			for _, id := range test.IDs {
				if _, ok := res.IDs[id]; !ok {
					t.Fatalf("want id(%v) to be in response map; map: %v", id, res.IDs)
				}
			}
		})
	}
}
