package syncs_test

import (
	"os"
	"path/filepath"
	"testing"

	"koding/klient/machine/client"
	"koding/klient/machine/client/clienttest"
	"koding/klient/machine/machinegroup/syncs"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/mounttest"
	"koding/klient/machine/mount/notify/silent"
	"koding/klient/machine/mount/sync/discard"
)

func TestSyncsAdd(t *testing.T) {
	wd, m, clean, err := mounttest.MountDirs()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	// Create new supervisor.
	mountID := mount.MakeID()
	s, err := syncs.New(syncs.SyncsOpts{
		WorkDir:       wd,
		NotifyBuilder: silent.Builder{},
		SyncBuilder:   discard.Builder{},
	})
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer s.Close()

	dynClient := func() (client.Client, error) {
		return clienttest.NewClient(), nil
	}
	if err := s.Add(mountID, m, dynClient); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if err := s.Add(mountID, m, dynClient); err == nil {
		t.Error("want err != nil; got nil")
	}

	// Check file structure.
	mountWD := filepath.Join(wd, "mount-"+string(mountID))
	if _, err := os.Stat(filepath.Join(mountWD, "data")); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}
}

func TestSyncsDrop(t *testing.T) {
	wd, m, clean, err := mounttest.MountDirs()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	// Create new sync.
	mountID := mount.MakeID()
	s, err := syncs.New(syncs.SyncsOpts{
		WorkDir:       wd,
		NotifyBuilder: silent.Builder{},
		SyncBuilder:   discard.Builder{},
	})
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer s.Close()

	if err := s.Add(mountID, m, func() (client.Client, error) {
		return clienttest.NewClient(), nil
	}); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if err := s.Drop(mountID); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Working directory should exist.
	if _, err := os.Stat(wd); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}

	// Mount sync working directory should not exist.
	mountWD := filepath.Join(wd, "mount-"+string(mountID))
	if _, err := os.Stat(mountWD); !os.IsNotExist(err) {
		t.Errorf("want err = os.ErrNotExist; got %v", err)
	}
}
