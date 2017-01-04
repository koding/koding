package mount

import (
	"encoding/json"
	"reflect"
	"testing"
)

func TestMountBook(t *testing.T) {
	var (
		idA = MakeID()
		idB = MakeID()
		idC = MakeID()
	)

	mounts := map[ID]Mount{
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
		PathID        ID
		RemotePath    string
		RemotePathIDs []ID
	}{
		"paths from mount A": {
			Path:          "/home/koding/a",
			PathID:        idA,
			RemotePath:    "/home/koding/remote/a",
			RemotePathIDs: []ID{idA},
		},
		"shared remote path": {
			Path:          "/home/koding/b",
			PathID:        idB,
			RemotePath:    "/home/koding/remote/shared",
			RemotePathIDs: []ID{idB, idC},
		},
		"unknown paths": {
			Path:          "/home/koding/unknown",
			PathID:        "",
			RemotePath:    "/home/koding/remote/unknown",
			RemotePathIDs: nil,
		},
	}

	mb := NewMountBook()
	for i, id := range []ID{idA, idB, idC} {
		if err := mb.Add(id, mounts[id]); err != nil {
			t.Fatalf("want err = nil; got %v (i:%d)", err, i)
		}
	}

	for name, test := range tests {
		t.Run(name, func(t *testing.T) {

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
	mb := NewMountBook()
	if err := mb.Add("duplicated", Mount{}); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if err := mb.Add("duplicated", Mount{}); err == nil {
		t.Fatalf("want err != nil; got nil")
	}
}

func TestMountBookJSON(t *testing.T) {
	mounts := map[ID]Mount{
		MakeID(): {
			Path:       "/home/koding/a",
			RemotePath: "/home/koding/remote/a",
		},
		MakeID(): {
			Path:       "/home/koding/b",
			RemotePath: "/home/koding/remote/b",
		},
	}

	mb := NewMountBook()
	for id, mount := range mounts {
		if err := mb.Add(id, mount); err != nil {
			t.Fatalf("want err = nil; got %v", err)
		}
	}

	data, err := json.Marshal(mb)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	mb = NewMountBook()
	if err = json.Unmarshal(data, mb); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	all := mb.All()
	if !reflect.DeepEqual(all, mounts) {
		t.Fatalf("want mount map = %#v; got %#v", mounts, all)
	}
}
