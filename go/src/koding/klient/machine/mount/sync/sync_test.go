package sync

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"

	"koding/klient/machine/client"
	"koding/klient/machine/client/clienttest"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/mounttest"
)

func TestSyncAdd(t *testing.T) {
	wd, m, clean, err := mounttest.MountDirs()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	// Add new mount.
	mountID := mount.MakeID()
	s, err := testSyncWithMount(wd, mountID, m)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if err := s.Add(mountID, m); err == nil {
		t.Error("want err != nil; got nil")
	}

	// Check file structure.
	mountWD := filepath.Join(wd, "mount-"+string(mountID))
	if _, err := os.Stat(filepath.Join(mountWD, "data")); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}
	if _, err := os.Stat(filepath.Join(mountWD, LocalIndexName)); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}
	if _, err := os.Stat(filepath.Join(mountWD, RemoteIndexName)); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}

	// Check indexes.
	info, err := s.Info(mountID)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if info.AllDiskSize == 0 {
		t.Error("want all disk size > 0")
	}

	expected := &Info{
		ID:           mountID,
		Mount:        m,
		SyncCount:    0,
		AllCount:     1,
		SyncDiskSize: 0,
		AllDiskSize:  info.AllDiskSize,
	}

	if !reflect.DeepEqual(info, expected) {
		t.Errorf("want info = %#v; got %#v", expected, info)
	}

	// Add files to remote and cache paths.
	if _, err := mounttest.TempFile(m.RemotePath); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if _, err := mounttest.TempFile(filepath.Join(mountWD, "data")); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// New add of existing mount.
	if s, err = testSyncWithMount(wd, mountID, m); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if info, err = s.Info(mountID); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// TODO: All count should be two, since synced file is not the one from
	// remote directory. This is temporary state since sync will balance
	// indexes, but should be handled anyway.
	expected.SyncCount = 1
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

	// Add new mount.
	mountID := mount.MakeID()
	s, err := testSyncWithMount(wd, mountID, m)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if err := s.Drop(mountID); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Working directory should exist.
	if _, err := os.Stat(wd); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}

	// Mount working directory should not exist.
	mountWD := filepath.Join(wd, "mount-"+string(mountID))
	if _, err := os.Stat(mountWD); !os.IsNotExist(err) {
		t.Errorf("want err = os.ErrNotExist; got %v", err)
	}
}

func testSyncWithMount(wd string, mountID mount.ID, m mount.Mount) (s *Sync, err error) {
	opts := SyncOpts{
		ClientFunc: func(mount.ID) (client.Client, error) {
			return clienttest.NewClient(), nil
		},
		WorkDir: wd,
	}

	s, err = New(opts)
	if err != nil {
		return nil, err
	}

	return s, s.Add(mountID, m)
}
