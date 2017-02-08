package supervisors_test

import (
	"os"
	"path/filepath"
	"testing"

	"koding/klient/machine/client"
	"koding/klient/machine/client/clienttest"
	"koding/klient/machine/machinegroup/supervisors"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/mounttest"
)

func TestSupervisorsAdd(t *testing.T) {
	wd, m, clean, err := mounttest.MountDirs()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	// Create new supervisor.
	mountID := mount.MakeID()
	s, err := supervisors.New(supervisors.SupervisorsOpts{WorkDir: wd})
	if err != nil {
		t.Fatalf("want err != nil; got nil")
	}
	defer s.Close()

	dynClient := func() (client.Client, error) {
		return clienttest.NewClient(), nil
	}
	if err := s.Add(mountID, m, dynClient); err != nil {
		t.Fatalf("want err != nil; got nil")
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

func TestSupervisorsDrop(t *testing.T) {
	wd, m, clean, err := mounttest.MountDirs()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	// Create new supervisor.
	mountID := mount.MakeID()
	s, err := supervisors.New(supervisors.SupervisorsOpts{WorkDir: wd})
	if err != nil {
		t.Fatalf("want err != nil; got nil")
	}
	defer s.Close()

	if err := s.Add(mountID, m, func() (client.Client, error) {
		return clienttest.NewClient(), nil
	}); err != nil {
		t.Fatalf("want err != nil; got nil")
	}

	if err := s.Drop(mountID); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Working directory should exist.
	if _, err := os.Stat(wd); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}

	// Mount supervisor working directory should not exist.
	mountWD := filepath.Join(wd, "mount-"+string(mountID))
	if _, err := os.Stat(mountWD); !os.IsNotExist(err) {
		t.Errorf("want err = os.ErrNotExist; got %v", err)
	}
}
