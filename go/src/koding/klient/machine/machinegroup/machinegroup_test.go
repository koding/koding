package machinegroup

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/machinegroup/addresses"
	"koding/klient/machine/machinegroup/aliases"
	"koding/klient/machine/machinetest"
	"koding/klient/storage"

	"github.com/boltdb/bolt"
)

func TestMachineGroupFreshStart(t *testing.T) {
	st, stop, err := testBoltStorage()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer stop()

	builder := machinetest.NewNilBuilder()
	g, err := New(testOptionsStorage(builder, st))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	// Nothing should be added to addresses storage.
	address, err := addresses.NewCached(st)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if len(address.Registered()) != 0 {
		t.Errorf("want no registered machines; got %v", address.Registered())
	}

	// Nothing should be added to aliases storage.
	alias, err := aliases.NewCached(st)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if len(alias.Registered()) != 0 {
		t.Errorf("want no registered machines; got %v", alias.Registered())
	}
}

func TestMachineGroupNoAliases(t *testing.T) {
	st, stop, err := testBoltStorage()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer stop()

	// Add initial address.
	id := machine.ID("servA")
	address, err := addresses.NewCached(st)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if err := address.Add(id, machinetest.TurnOnAddr()); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if len(address.Registered()) != 1 {
		t.Errorf("want one registered machine; got %v", address.Registered())
	}

	builder := machinetest.NewNilBuilder()
	g, err := New(testOptionsStorage(builder, st))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	// Machine group should add alias for missing ID.
	alias, err := aliases.NewCached(st)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if len(alias.Registered()) != 1 {
		t.Errorf("want one registered machine; got %v", address.Registered())
	}

	// Dynamic client should be started.
	if err := builder.WaitForBuild(time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if builder.BuildsCount() != 1 {
		t.Errorf("want dynamic builds number = 1; got %d", builder.BuildsCount())
	}
}

// testOptions returns default Group options used for testing purposes.
func testOptions(b machine.ClientBuilder) *GroupOpts {
	return testOptionsStorage(b, nil)
}

// testOptionsStorage returns default Group options used for testing purposes.
// This function allows to specify custom storage.
func testOptionsStorage(b machine.ClientBuilder, st storage.ValueInterface) *GroupOpts {
	return &GroupOpts{
		Storage:         st,
		Builder:         b,
		DynAddrInterval: 10 * time.Millisecond,
		PingInterval:    50 * time.Millisecond,
	}
}

// testBoltStorage creates a temporary bolt database. In order to clean
// resources, stop function must be run at the end of each test.
func testBoltStorage() (st storage.ValueInterface, stop func(), err error) {
	testpath, err := ioutil.TempDir("", "machinegroup")
	if err != nil {
		return nil, nil, err
	}

	db, err := bolt.Open(filepath.Join(testpath, "test.db"), 0600, nil)
	if err != nil {
		return nil, nil, err
	}
	stop = func() {
		db.Close()
		os.RemoveAll(testpath)
	}

	bstorage, err := storage.NewBoltStorageBucket(db, []byte("klient"))
	if err != nil {
		stop()
		return nil, nil, err
	}

	return &storage.EncodingStorage{
		Interface: bstorage,
	}, stop, nil
}
