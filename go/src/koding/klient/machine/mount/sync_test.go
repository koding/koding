package mount_test

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
	sA, err := mount.NewSync(mountID, m, defaultOptions(wd))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer sA.Close()
	sA.UpdateIndex()

	// Check file structure.
	if _, err := os.Stat(filepath.Join(wd, "data")); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}
	if _, err := os.Stat(filepath.Join(wd, mount.IndexFileName)); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}

	// Check indexes.
	info := sA.Info()
	if info == nil {
		t.Fatalf("want info != nil; got nil")
	}
	if info.DiskSizeAll == 0 {
		t.Error("want all disk size > 0")
	}

	expected := &mount.Info{
		ID:          mountID,
		Mount:       m,
		Count:       1,
		CountAll:    2,
		DiskSize:    info.DiskSize,
		DiskSizeAll: info.DiskSizeAll,
		Queued:      2,
		Syncing:     info.Syncing,
	}

	if !reflect.DeepEqual(info, expected) {
		t.Fatalf("want info = %#v; got %#v", expected, info)
	}

	// Add files to remote and cache paths.
	if _, err := mounttest.TempFile(m.RemotePath); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if _, err := mounttest.TempFile(filepath.Join(wd, "data")); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// New add of existing mount.
	sB, err := mount.NewSync(mountID, m, defaultOptions(wd))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer sB.Close()
	sB.UpdateIndex()

	if info = sB.Info(); info == nil {
		t.Fatalf("want info != nil; got nil")
	}

	expected = &mount.Info{
		ID:          mountID,
		Mount:       m,
		Count:       2,
		CountAll:    3,
		DiskSize:    info.DiskSize,
		DiskSizeAll: info.DiskSizeAll,
		Queued:      3,
		Syncing:     info.Syncing,
	}

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
	s, err := mount.NewSync(mountID, m, defaultOptions(wd))
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

func defaultOptions(wd string) mount.Options {
	return mount.Options{
		ClientFunc: func() (client.Client, error) {
			return clienttest.NewClient(), nil
		},
		SSHFunc: func() (host string, port int, err error) {
			return "host", 0, nil
		},
		NotifyBuilder: silent.Builder{},
		SyncBuilder:   discard.Builder{},
		WorkDir:       wd,
	}
}
