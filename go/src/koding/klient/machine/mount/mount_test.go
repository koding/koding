package mount_test

import (
	"encoding/json"
	"reflect"
	"sort"
	"testing"

	"koding/klient/machine/mount"
)

func TestMakeIDString(t *testing.T) {
	tests := map[string]struct {
		Tok     string
		ID      mount.ID
		IsValid bool
	}{
		"valid UUIDv4": {
			Tok:     "e2d92c39-bcc6-45c8-86f6-7ca114ec7e06",
			ID:      mount.ID("e2d92c39-bcc6-45c8-86f6-7ca114ec7e06"),
			IsValid: true,
		},
		"valid with braces": {
			Tok:     "52560e13-ad72-4cef-a3d7-f52ca197168d",
			ID:      mount.ID("52560e13-ad72-4cef-a3d7-f52ca197168d"),
			IsValid: true,
		},
		"invalid UUIDv1": {
			Tok:     "123e4567-e89b-12d3-a456-426655440000",
			ID:      mount.ID(""),
			IsValid: false,
		},
		"invalid": {
			Tok:     "invalid",
			ID:      mount.ID(""),
			IsValid: false,
		},
		"empty token": {
			Tok:     "",
			ID:      mount.ID(""),
			IsValid: false,
		},
	}

	for name, test := range tests {
		test := test // Capture range variable.
		t.Run(name, func(t *testing.T) {
			t.Parallel()

			mountID, err := mount.IDFromString(test.Tok)
			if (err == nil) != test.IsValid {
				t.Fatalf("want err == nil to be %t; got %v", test.IsValid, err)
			}

			if mountID != test.ID {
				t.Errorf("want mount ID = %s; got %s", test.ID, mountID)
			}
		})
	}
}

func TestMountBook(t *testing.T) {
	var (
		idA = mount.MakeID()
		idB = mount.MakeID()
		idC = mount.MakeID()
	)

	mounts := map[mount.ID]mount.Mount{
		idA: {
			Path:       "/home/koding/a",
			RemotePath: "/home/koding/remote/a",
		},
		idB: {
			Path:       "/home/koding/b",
			RemotePath: "/home/koding/remote/shared",
		},
		idC: {
			Path:       "/home/koding/c",
			RemotePath: "/home/koding/remote/shared",
		},
	}

	tests := map[string]struct {
		Path          string
		PathID        mount.ID
		RemotePath    string
		RemotePathIDs mount.IDSlice
	}{
		"paths from mount A": {
			Path:          "/home/koding/a",
			PathID:        idA,
			RemotePath:    "/home/koding/remote/a",
			RemotePathIDs: mount.IDSlice{idA},
		},
		"shared remote path": {
			Path:          "/home/koding/b",
			PathID:        idB,
			RemotePath:    "/home/koding/remote/shared",
			RemotePathIDs: mount.IDSlice{idB, idC},
		},
		"unknown paths": {
			Path:          "/home/koding/unknown",
			PathID:        "",
			RemotePath:    "/home/koding/remote/unknown",
			RemotePathIDs: nil,
		},
	}

	mb := mount.NewMountBook()
	for i, id := range []mount.ID{idA, idB, idC} {
		if err := mb.Add(id, mounts[id]); err != nil {
			t.Fatalf("want err = nil; got %v (i:%d)", err, i)
		}
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()

			sort.Sort(test.RemotePathIDs)
			id, err := mb.Path(test.Path)
			if test.PathID == "" && err == nil {
				t.Errorf("want err != nil, got nil")
			}
			if test.PathID != "" && err != nil {
				t.Errorf("want ID = %s, got err = %v", test.PathID, err)
			}
			if test.PathID != id {
				t.Errorf("want ID = %s, got %s", test.PathID, id)
			}

			ids, err := mb.RemotePath(test.RemotePath)
			sort.Sort(ids)
			if test.RemotePathIDs == nil && err == nil {
				t.Errorf("want err != nil, got nil")
			}
			if test.RemotePathIDs != nil && err != nil {
				t.Errorf("want IDs = %v, got err = %v", test.RemotePathIDs, err)
			}
			if !reflect.DeepEqual(test.RemotePathIDs, ids) {
				t.Errorf("want IDs = %v, got %v", test.RemotePathIDs, ids)
			}
		})
	}

}

func TestMountBookDuplicatedID(t *testing.T) {
	mb := mount.NewMountBook()
	if err := mb.Add("duplicated", mount.Mount{}); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if err := mb.Add("duplicated", mount.Mount{}); err == nil {
		t.Fatalf("want err != nil; got nil")
	}
}

func TestMountBookJSON(t *testing.T) {
	mounts := map[mount.ID]mount.Mount{
		mount.MakeID(): {
			Path:       "/home/koding/a",
			RemotePath: "/home/koding/remote/a",
		},
		mount.MakeID(): {
			Path:       "/home/koding/b",
			RemotePath: "/home/koding/remote/b",
		},
	}

	mb := mount.NewMountBook()
	for id, mount := range mounts {
		if err := mb.Add(id, mount); err != nil {
			t.Fatalf("want err = nil; got %v", err)
		}
	}

	data, err := json.Marshal(mb)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	mb = mount.NewMountBook()
	if err = json.Unmarshal(data, mb); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	all := mb.All()
	if !reflect.DeepEqual(all, mounts) {
		t.Fatalf("want mount map = %#v; got %#v", mounts, all)
	}
}
