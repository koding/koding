package sync_test

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"

	"koding/klient/machine/client"
	"koding/klient/machine/client/clienttest"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/mounttest"
	"koding/klient/machine/mount/notify/silent"
	msync "koding/klient/machine/mount/sync"
	"koding/klient/machine/mount/sync/discard"
)

func TestSyncNew(t *testing.T) {
	wd, m, clean, err := mounttest.MountDirs()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	// Create new Sync.
	mountID := mount.MakeID()
	sA, err := msync.NewSync(mountID, m, defaultSyncOpts(wd))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer sA.Close()

	// Check file structure.
	if _, err := os.Stat(filepath.Join(wd, "data")); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}
	if _, err := os.Stat(filepath.Join(wd, msync.IndexFileName)); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}

	// Check indexes.
	info := sA.Info()
	if info == nil {
		t.Fatalf("want info != nil; got nil")
	}
	if info.AllDiskSize == 0 {
		t.Error("want all disk size > 0")
	}

	expected := &msync.Info{
		ID:           mountID,
		Mount:        m,
		SyncCount:    0,
		AllCount:     1,
		SyncDiskSize: 0,
		AllDiskSize:  info.AllDiskSize,
		Queued:       0,
		Syncing:      0,
	}

	if !reflect.DeepEqual(info, expected) {
		t.Errorf("want info = %#v; got %#v", expected, info)
	}

	// Add files to remote and cache paths.
	if _, err := mounttest.TempFile(m.RemotePath); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if _, err := mounttest.TempFile(filepath.Join(wd, "data")); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// New add of existing mount.
	sB, err := msync.NewSync(mountID, m, defaultSyncOpts(wd))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer sB.Close()

	if info = sB.Info(); info == nil {
		t.Fatalf("want info != nil; got nil")
	}

	// TODO: All count should be two, since synced file is not the one from
	// remote directory. This is temporary state since sync will balance
	// indexes, but should be handled anyway.
	expected.SyncCount = 0
	expected.SyncDiskSize = info.SyncDiskSize

	if !reflect.DeepEqual(info, expected) {
		t.Errorf("want info = %#v; got %#v", expected, info)
	}
}

func TestSyncDrop(t *testing.T) {
	wd, m, clean, err := mounttest.MountDirs()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	// Create new Sync.
	mountID := mount.MakeID()
	s, err := msync.NewSync(mountID, m, defaultSyncOpts(wd))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer s.Close()

	if err := s.Drop(); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Working directory should not exist.
	if _, err := os.Stat(wd); !os.IsNotExist(err) {
		t.Errorf("want err = os.ErrNotExist; got %v", err)
	}
}

func defaultSyncOpts(wd string) msync.SyncOpts {
	return msync.SyncOpts{
		ClientFunc: func() (client.Client, error) {
			return clienttest.NewClient(), nil
		},
		NotifyBuilder: silent.SilentBuilder{},
		SyncBuilder:   discard.DiscardBuilder{},
		WorkDir:       wd,
	}
}
