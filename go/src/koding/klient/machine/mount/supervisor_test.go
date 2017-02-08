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
)

func TestSupervisorNew(t *testing.T) {
	wd, m, clean, err := mounttest.MountDirs()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	// Create new supervisor.
	mountID := mount.MakeID()
	opts := mount.SupervisorOpts{
		ClientFunc: func() (client.Client, error) {
			return clienttest.NewClient(), nil
		},
		WorkDir: wd,
	}
	sA, err := mount.NewSupervisor(mountID, m, opts)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer sA.Close()

	// Check file structure.
	if _, err := os.Stat(filepath.Join(wd, "data")); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}
	if _, err := os.Stat(filepath.Join(wd, mount.LocalIndexName)); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}
	if _, err := os.Stat(filepath.Join(wd, mount.RemoteIndexName)); err != nil {
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

	expected := &mount.Info{
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
	sB, err := mount.NewSupervisor(mountID, m, opts)
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
	expected.SyncCount = 1
	expected.SyncDiskSize = info.SyncDiskSize

	if !reflect.DeepEqual(info, expected) {
		t.Errorf("want info = %#v; got %#v", expected, info)
	}
}

func TestSupervisorDrop(t *testing.T) {
	wd, m, clean, err := mounttest.MountDirs()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	// Create new supervisor.
	mountID := mount.MakeID()
	opts := mount.SupervisorOpts{
		ClientFunc: func() (client.Client, error) {
			return clienttest.NewClient(), nil
		},
		WorkDir: wd,
	}
	s, err := mount.NewSupervisor(mountID, m, opts)
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
