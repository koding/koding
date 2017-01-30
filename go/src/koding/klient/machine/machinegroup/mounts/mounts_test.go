package mounts

import (
	"fmt"
	"reflect"
	"sort"
	"testing"

	"koding/klient/machine"
	"koding/klient/machine/mount"
)

func TestMountsPath(t *testing.T) {
	tests := map[string]struct {
		Path    string
		MountID mount.ID
		Valid   bool
	}{
		"valid mount from A machine": {
			Path:    "/home/koding/b",
			MountID: "mountAB",
			Valid:   true,
		},
		"valid mount from B machine": {
			Path:    "/home/koding/d",
			MountID: "mountBA",
			Valid:   true,
		},
		"non absolute path": {
			Path:    "../.",
			MountID: "",
			Valid:   false,
		},
		"unknown path": {
			Path:    "/home/koding/unknown",
			MountID: "",
			Valid:   false,
		},
	}

	ms, err := mountsObject()
	if err != nil {
		t.Fatal(err)
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			mountID, err := ms.Path(test.Path)
			if (err == nil) != test.Valid {
				t.Fatalf("want err == nil => %t; got err %v", test.Valid, err)
			}

			if err == nil && test.MountID != mountID {
				t.Fatalf("want mount ID = %s; got %s", test.MountID, mountID)
			}
		})
	}
}

func TestMountsRemotePath(t *testing.T) {
	tests := map[string]struct {
		RemotePath string
		MountIDs   mount.IDSlice
		Valid      bool
	}{
		"remote from A machine": {
			RemotePath: "/home/koding/remote/c",
			MountIDs:   mount.IDSlice{"mountAC"},
			Valid:      true,
		},
		"remote from A and B machines": {
			RemotePath: "/home/koding/remote/a",
			MountIDs:   mount.IDSlice{"mountAA", "mountBA"},
			Valid:      true,
		},
		"unknown path": {
			RemotePath: "/home/koding/unknown",
			MountIDs:   nil,
			Valid:      false,
		},
	}

	ms, err := mountsObject()
	if err != nil {
		t.Fatal(err)
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			mountIDs, err := ms.RemotePath(test.RemotePath)
			sort.Sort(mountIDs)
			if (err == nil) != test.Valid {
				t.Fatalf("want err == nil => %t; got err %v", test.Valid, err)
			}

			if err == nil && !reflect.DeepEqual(mountIDs, test.MountIDs) {
				t.Fatalf("want mount ID = %v; got %v", test.MountIDs, mountIDs)
			}
		})
	}
}

func TestMountsMachineID(t *testing.T) {
	tests := map[string]struct {
		MountID mount.ID
		ID      machine.ID
		Valid   bool
	}{
		"machine A mount": {
			MountID: "mountAC",
			ID:      "machineA",
			Valid:   true,
		},
		"machine B mount": {
			MountID: "mountBA",
			ID:      "machineB",
			Valid:   true,
		},
		"unknown mount ID": {
			MountID: "unknown",
			ID:      "",
			Valid:   false,
		},
	}

	ms, err := mountsObject()
	if err != nil {
		t.Fatal(err)
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			id, err := ms.MachineID(test.MountID)
			if (err == nil) != test.Valid {
				t.Fatalf("want err == nil => %t; got err %v", test.Valid, err)
			}

			if err == nil && test.ID != id {
				t.Fatalf("want machine ID = %s; got %s", test.ID, id)
			}
		})
	}
}

func TestMountsRemove(t *testing.T) {
	ms, err := mountsObject()
	if err != nil {
		t.Fatal(err)
	}

	if err := ms.Remove("mountAA"); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}
	all, err := ms.All("machineA")
	if err != nil {
		t.Errorf("want err = nil; got %v", err)
	}
	if l := len(all); l != 2 {
		t.Errorf("want 2 mounts in machine A; got %d", l)
	}

	if err := ms.Remove("mountBA"); err != nil {
		t.Errorf("want err = nil; got %v", err)
	}
	if _, err := ms.All("machineB"); err == nil {
		t.Errorf("want err != nil; got nil")
	}
}

func TestMountsAddValidate(t *testing.T) {
	tests := map[string]struct {
		ID      machine.ID
		MountID mount.ID
		Mount   mount.Mount
	}{
		"local path already taken": {
			ID:      "machineX",
			MountID: "mountAAX",
			Mount: mount.Mount{
				Path:       "/home/koding/a",
				RemotePath: "/home/koding/remote/a",
			},
		},
		"mount ID already exist": {
			ID:      "machineX",
			MountID: "mountAB",
			Mount: mount.Mount{
				Path:       "/home/koding/X",
				RemotePath: "/home/koding/remote/b",
			},
		},
	}

	ms, err := mountsObject()
	if err != nil {
		t.Fatal(err)
	}

	for name, test := range tests {
		t.Run(name, func(t *testing.T) {
			if err := ms.Add(test.ID, test.MountID, test.Mount); err == nil {
				fmt.Errorf("want err != nil; got nil")
			}
		})
	}
}

func mountsObject() (*Mounts, error) {
	data := []struct {
		ID      machine.ID
		MountID mount.ID
		Mount   mount.Mount
	}{
		{
			ID:      "machineA",
			MountID: "mountAA",
			Mount: mount.Mount{
				Path:       "/home/koding/a",
				RemotePath: "/home/koding/remote/a",
			},
		}, {
			ID:      "machineA",
			MountID: "mountAB",
			Mount: mount.Mount{
				Path:       "/home/koding/b",
				RemotePath: "/home/koding/remote/b",
			},
		}, {
			ID:      "machineA",
			MountID: "mountAC",
			Mount: mount.Mount{
				Path:       "/home/koding/c",
				RemotePath: "/home/koding/remote/c",
			},
		}, {
			ID:      "machineB",
			MountID: "mountBA",
			Mount: mount.Mount{
				Path:       "/home/koding/d",
				RemotePath: "/home/koding/remote/a",
			},
		},
	}

	ms := New()
	for i, d := range data {
		if err := ms.Add(d.ID, d.MountID, d.Mount); err != nil {
			return nil, fmt.Errorf("want err = nil; got %v (i:%d)", err, i)
		}
	}

	return ms, nil
}
