package machinegroup

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/client"
	"koding/klient/machine/client/clienttest"
	"koding/klient/machine/machinegroup/addresses"
	"koding/klient/machine/machinegroup/aliases"
	"koding/klient/machine/machinegroup/metadata"
	"koding/klient/machine/machinegroup/mounts"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/mounttest"
	"koding/klient/machine/mount/notify/silent"
	"koding/klient/machine/mount/sync/discard"
	"koding/klient/storage"

	"github.com/boltdb/bolt"
)

func TestMachineGroupFreshStart(t *testing.T) {
	st, stop, err := testBoltStorage()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer stop()

	wd, err := ioutil.TempDir("", "machinegroup")
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer os.RemoveAll(wd)

	builder := clienttest.NewBuilder(nil)
	g, err := New(testOptionsStorage(wd, builder, st))
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

	// Nothing should be added to metadata storage.
	meta, err := metadata.NewCached(st)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if len(meta.Registered()) != 0 {
		t.Errorf("want no registered machines; got %v", meta.Registered())
	}

	// Nothing should be added to mounts storage.
	mount, err := mounts.NewCached(st)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if len(mount.Registered()) != 0 {
		t.Errorf("want no registered machines; got %v", mount.Registered())
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
	if err := address.Add(id, clienttest.TurnOnAddr()); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if err := address.Cache(); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if len(address.Registered()) != 1 {
		t.Errorf("want one registered machine; got %v", address.Registered())
	}

	wd, err := ioutil.TempDir("", "machinegroup")
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer os.RemoveAll(wd)

	builder := clienttest.NewBuilder(nil)
	g, err := New(testOptionsStorage(wd, builder, st))
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
		t.Errorf("want one registered machine; got %v", alias.Registered())
	}

	// Dynamic client should be started.
	if err := builder.WaitForBuild(time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if builder.BuildsCount() != 1 {
		t.Errorf("want dynamic builds number = 1; got %d", builder.BuildsCount())
	}
}

func TestMachineGroupMount(t *testing.T) {
	st, stop, err := testBoltStorage()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer stop()

	// Create two testing mounts.
	wd, ms, clean, err := mounttest.MultiMountDirs(2)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	// Add machine address in order to trigger valid server and not reach timeout.
	id := machine.ID("servA")
	address, err := addresses.NewCached(st)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if err := address.Add(id, clienttest.TurnOnAddr()); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if err := address.Cache(); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Add two mounts.
	mountIDA, mountIDB := mount.MakeID(), mount.MakeID()
	mgMount, err := mounts.NewCached(st)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if err := mgMount.Add(id, mountIDA, ms[0]); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if err := mgMount.Add(id, mountIDB, ms[1]); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if len(mgMount.Registered()) != 1 {
		t.Errorf("want one registered machine; got %v", mgMount.Registered())
	}
	allm, err := mgMount.All(id)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if len(allm) != 2 {
		t.Errorf("want two registered mounts; got %v", allm)
	}

	builder := clienttest.NewBuilder(nil)
	g, err := New(testOptionsStorage(wd, builder, st))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	// Machine group should add alias for missing ID pointed by mount.
	alias, err := aliases.NewCached(st)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if len(alias.Registered()) != 1 {
		t.Errorf("want one registered machine; got %v", alias.Registered())
	}

	// Dynamic client should be started for added mount.
	if err := builder.WaitForBuild(time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if builder.BuildsCount() != 1 {
		t.Errorf("want dynamic builds number = 1; got %d", builder.BuildsCount())
	}

	// Mount cache directories should be created.
	if err := mounttest.StatCacheDir(wd, mountIDA); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}
	if err := mounttest.StatCacheDir(wd, mountIDB); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}
}

// testOptions returns default Group options used for testing purposes.
func testOptions(wd string, b client.Builder) *Options {
	return testOptionsStorage(wd, b, nil)
}

// testOptionsStorage returns default Group options used for testing purposes.
// This function allows to specify custom storage.
func testOptionsStorage(wd string, b client.Builder, st storage.ValueInterface) *Options {
	return &Options{
		Storage:         st,
		Builder:         b,
		NotifyBuilder:   silent.Builder{},
		SyncBuilder:     discard.Builder{},
		DynAddrInterval: 10 * time.Millisecond,
		PingInterval:    50 * time.Millisecond,
		WorkDir:         wd,
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
