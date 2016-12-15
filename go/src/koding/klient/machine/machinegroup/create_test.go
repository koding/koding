package machinegroup

import (
	"reflect"
	"testing"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/machinetest"
)

func TestCreate(t *testing.T) {
	var (
		builder = machinetest.NewNilBuilder()

		idA = machine.ID("servA")
		idB = machine.ID("servB")
	)

	g, err := New(testOptions(builder))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	const AddedServersCount = 2
	req := &CreateRequest{
		Addresses: map[machine.ID][]machine.Addr{
			idA: {machinetest.TurnOffAddr()},
			idB: {machinetest.TurnOnAddr()},
		},
	}

	res, err := g.Create(req)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if la := len(res.Aliases); la != AddedServersCount {
		t.Fatalf("want aliases count = %d; got: %d", AddedServersCount, la)
	}

	// Check generated aliases which must be unique and not empty.
	aliasA := res.Aliases[idA]
	if aliasA == "" {
		t.Errorf("want aliasA != ``; got ``")
	}
	aliasB := res.Aliases[idB]
	if aliasB == "" {
		t.Errorf("want aliasB != ``; got ``")
	}
	if aliasA == aliasB {
		t.Errorf("want aliasA != aliasB; got %s == %s", aliasA, aliasB)
	}

	for i := 0; i < AddedServersCount; i++ {
		if err := builder.WaitForBuild(time.Second); err != nil {
			t.Fatalf("want err = nil; got %v", err)
		}
	}

	// Already added, update statuses; don't change aliases.
	res, err = g.Create(req)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if aliasA != res.Aliases[idA] {
		t.Errorf("want aliasA = %s; got %s", aliasA, res.Aliases[idA])
	}
	if aliasB != res.Aliases[idB] {
		t.Errorf("want aliasB = %s; got %s", aliasB, res.Aliases[idB])
	}

	// Machines were pinged and they clients were build.
	statuses := map[machine.ID]machine.Status{
		idA: machine.Status{State: machine.StateOffline},
		idB: machine.Status{State: machine.StateOnline},
	}
	if !reflect.DeepEqual(statuses, res.Statuses) {
		t.Fatalf("want statuses = %#v; got %#v", statuses, res.Statuses)
	}
}
