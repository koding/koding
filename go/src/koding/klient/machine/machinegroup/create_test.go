package machinegroup

import (
	"io/ioutil"
	"os"
	"reflect"
	"strconv"
	"testing"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/client/clienttest"
	"koding/klient/machine/mount/mounttest"
)

func TestCreate(t *testing.T) {
	var (
		builder = clienttest.NewBuilder(nil)

		idA = machine.ID("servA")
		idB = machine.ID("servB")
	)

	wd, err := ioutil.TempDir("", "create")
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer os.RemoveAll(wd)

	g, err := New(testOptions(wd, builder))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	const AddedServersCount = 2
	req := &CreateRequest{
		Addresses: map[machine.ID][]machine.Addr{
			idA: {clienttest.TurnOffAddr()},
			idB: {clienttest.TurnOnAddr()},
		},
		Metadata: map[machine.ID]*machine.Metadata{
			idA: &machine.Metadata{Label: string(idA)},
			idB: &machine.Metadata{Label: string(idB)},
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
		idA: {State: machine.StateOffline},
		idB: {State: machine.StateOnline},
	}
	if !reflect.DeepEqual(statuses, res.Statuses) {
		t.Fatalf("want statuses = %#v; got %#v", statuses, res.Statuses)
	}
}

func TestCreateBalance(t *testing.T) {
	var (
		client  = clienttest.NewClient()
		builder = clienttest.NewBuilder(client)
		id      = machine.ID("serv")
	)

	wd, err := ioutil.TempDir("", "create")
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer os.RemoveAll(wd)

	g, err := New(testOptions(wd, builder))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	// Add connected remote machine.
	if _, err := testCreateOn(g, builder, id); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Create with empty addresses should remove previously added machine.
	if _, err := g.Create(&CreateRequest{}); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Client context should be closed.
	if err := clienttest.WaitForContextClose(client.Context(), time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
}

func TestCreateBalanceStaleMount(t *testing.T) {
	var (
		client  = clienttest.NewClient()
		builder = clienttest.NewBuilder(client)
		id      = machine.ID("serv")
	)

	wd, m, clean, err := mounttest.MountDirs()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	g, err := New(testOptions(wd, builder))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	// Add connected remote machine.
	if _, err := testCreateOn(g, builder, id); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Add testing mount.
	if _, err := testAddMount(g, id, m); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Create with empty addresses should not remove previously added machine
	// because of mount existence.
	if _, err := g.Create(&CreateRequest{}); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Client context should not be closed.
	if err := clienttest.WaitForContextClose(client.Context(), 50*time.Millisecond); err == nil {
		t.Fatalf("want err != nil; got nil")
	}
}

func testCreateOn(g *Group, builder *clienttest.Builder, ids ...machine.ID) (aliases map[machine.ID]string, err error) {
	req := &CreateRequest{
		Addresses: make(map[machine.ID][]machine.Addr),
		Metadata:  make(map[machine.ID]*machine.Metadata),
	}

	for n, id := range ids {
		req.Addresses[id] = []machine.Addr{
			clienttest.TurnOnAddr(),
		}
		req.Metadata[id] = &machine.Metadata{
			Label: "ID_" + strconv.Itoa(n+1),
		}
	}

	res, err := g.Create(req)
	if err != nil {
		return nil, err
	}

	for i := 0; i < len(req.Addresses); i++ {
		if err := builder.WaitForBuild(time.Second); err != nil {
			return nil, err
		}
	}

	return res.Aliases, nil
}
