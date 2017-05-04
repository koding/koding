package machinegroup

import (
	"errors"
	"os"
	"reflect"
	"testing"

	"koding/klient/machine"
	"koding/klient/machine/client/clienttest"
	"koding/klient/machine/index"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/mounttest"
)

func TestHeadMount(t *testing.T) {
	var (
		builder = clienttest.NewBuilder(nil)
		id      = machine.ID("serv")
	)

	wd, m, clean, err := mounttest.MountDirs()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	g, err := New(testOptions(wd, builder))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	// Add connected remote machine.
	if _, err := testCreateOn(g, builder, id); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Head testing mount.
	headMountReq := &HeadMountRequest{
		MountRequest{
			ID:    id,
			Mount: m,
		},
	}
	headMountRes, err := g.HeadMount(headMountReq)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if headMountRes.ExistMountID != "" {
		t.Errorf("want mount does not exist; got: %s", headMountRes.ExistMountID)
	}
	if headMountRes.AbsRemotePath != m.RemotePath {
		t.Errorf("want remote path = %s; got %s", m.RemotePath, headMountRes.AbsRemotePath)
	}

	// Compare indexes.
	idx, err := index.NewIndexFiles(m.RemotePath, nil)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if resc, idxc := headMountRes.AllCount, idx.Tree().Count(); resc != idxc {
		t.Errorf("want file count = %d; got %d", idxc, resc)
	}
	if resds, idxds := headMountRes.AllDiskSize, idx.Tree().DiskSize(); resds != idxds {
		t.Errorf("want disk size = %d; got %d", idxds, resds)
	}
}

func TestAddMount(t *testing.T) {
	var (
		builder = clienttest.NewBuilder(nil)
		id      = machine.ID("serv")
	)

	wd, m, clean, err := mounttest.MountDirs()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	g, err := New(testOptions(wd, builder))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	// Add connected remote machine.
	if _, err := testCreateOn(g, builder, id); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Add testing mount.
	addMountReq := &AddMountRequest{
		MountRequest: MountRequest{
			ID:    id,
			Mount: m,
		},
	}
	addMountRes, err := g.AddMount(addMountReq)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if addMountRes.MountID == "" {
		t.Errorf("want not empty mount ID")
	}

	// Cache directory should exist.
	if err := mounttest.StatCacheDir(wd, addMountRes.MountID); err != nil {
		t.Errorf("want err = nil, got %v", err)
	}
}

func TestListMount(t *testing.T) {
	var (
		builder = clienttest.NewBuilder(nil)

		idA = machine.ID("servA")
		idB = machine.ID("servB")
	)

	// There will be two mounts using by machine with idA.
	wd, ms, clean, err := mounttest.MultiMountDirs(2)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	g, err := New(testOptions(wd, builder))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	// Add two connected remote machines.
	aliases, err := testCreateOn(g, builder, idA, idB)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Add testing mounts to A machine.
	mountIDs, err := testAddMount(g, idA, ms...)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	tests := map[string]struct {
		LMReq         ListMountRequest
		ConcatIDsInfo map[string]mount.Info
	}{
		"all mounts": {
			ConcatIDsInfo: map[string]mount.Info{
				aliases[idA] + string(mountIDs[0]): {
					ID:    mountIDs[0],
					Mount: ms[0],
				},
				aliases[idA] + string(mountIDs[1]): {
					ID:    mountIDs[1],
					Mount: ms[1],
				},
			},
		},
		"all mounts from machine A": {
			LMReq: ListMountRequest{
				ID: idA,
			},
			ConcatIDsInfo: map[string]mount.Info{
				aliases[idA] + string(mountIDs[0]): {
					ID:    mountIDs[0],
					Mount: ms[0],
				},
				aliases[idA] + string(mountIDs[1]): {
					ID:    mountIDs[1],
					Mount: ms[1],
				},
			},
		},
		"all mounts from machine B": {
			LMReq: ListMountRequest{
				ID: idB,
			},
			ConcatIDsInfo: map[string]mount.Info{},
		},
		"filter by mount ID": {
			LMReq: ListMountRequest{
				MountID: mountIDs[1],
			},
			ConcatIDsInfo: map[string]mount.Info{
				aliases[idA] + string(mountIDs[1]): {
					ID:    mountIDs[1],
					Mount: ms[1],
				},
			},
		},
		"filter by mount ID and machine A": {
			LMReq: ListMountRequest{
				ID:      idA,
				MountID: mountIDs[0],
			},
			ConcatIDsInfo: map[string]mount.Info{
				aliases[idA] + string(mountIDs[0]): {
					ID:    mountIDs[0],
					Mount: ms[0],
				},
			},
		},
		"filter by mount ID and machine B": {
			LMReq: ListMountRequest{
				ID:      idB,
				MountID: mountIDs[0],
			},
			ConcatIDsInfo: map[string]mount.Info{},
		},
		"unknown machine ID": {
			LMReq: ListMountRequest{
				ID:      "unknown",
				MountID: mountIDs[0],
			},
			ConcatIDsInfo: map[string]mount.Info{},
		},
		"unknown mount ID": {
			LMReq: ListMountRequest{
				ID:      idB,
				MountID: "unknown",
			},
			ConcatIDsInfo: map[string]mount.Info{},
		},
	}

	for name, test := range tests {
		test := test // Capture range variable.
		t.Run(name, func(t *testing.T) {
			t.Parallel()

			listMountRes, err := g.ListMount(&test.LMReq)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			if listMountRes.Mounts == nil {
				t.Fatalf("want mount list response != nil; got nil")
			}

			// Prepare results.
			concatIDsRes, n := make(map[string]mount.Info), 0
			for alias, infos := range listMountRes.Mounts {
				for _, info := range infos {
					concatIDsRes[alias+string(info.ID)] = mount.Info{
						ID:    info.ID,
						Mount: info.Mount,
					}
					n++
				}
			}

			if l := len(test.ConcatIDsInfo); l != n {
				t.Errorf("want returned mounts count = %d; got %d", l, n)
			}

			if !reflect.DeepEqual(test.ConcatIDsInfo, concatIDsRes) {
				t.Errorf("want result = %#v; got %#v", test.ConcatIDsInfo, concatIDsRes)
			}
		})
	}
}

func TestUmount(t *testing.T) {
	var (
		builder = clienttest.NewBuilder(nil)
		id      = machine.ID("serv")
	)

	// There will be three mounts.
	wd, ms, clean, err := mounttest.MultiMountDirs(3)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	g, err := New(testOptions(wd, builder))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	// Add connected remote machine.
	if _, err := testCreateOn(g, builder, id); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Add testing mounts.
	mountIDs, err := testAddMount(g, id, ms...)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Helper functions that checks if directory exists or not.
	shouldAccessible := func(mountID mount.ID) {
		if err := mounttest.StatCacheDir(wd, mountID); err != nil {
			t.Errorf("want err = nil, got %v", err)
		}
	}
	shouldNotExist := func(mountID mount.ID) {
		if err := mounttest.StatCacheDir(wd, mountID); !os.IsNotExist(err) {
			t.Errorf("want err = %v, got %v", os.ErrNotExist, err)
		}
	}

	shouldAccessible(mountIDs[0])
	shouldAccessible(mountIDs[1])
	shouldAccessible(mountIDs[2])

	// Unmount by mount.ID.
	umountReq := &UmountRequest{
		Identifier: string(mountIDs[1]),
	}
	umountRes, err := g.Umount(umountReq)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if umountRes.MountID != mountIDs[1] {
		t.Errorf("want mount ID: %s; got %s", mountIDs[1], umountRes.MountID)
	}
	if umountRes.Mount != ms[1] || umountRes.MountID != mountIDs[1] {
		t.Errorf("want mount %s; got %s", ms[1], umountRes.Mount)
	}

	shouldAccessible(mountIDs[0])
	shouldNotExist(mountIDs[1])
	shouldAccessible(mountIDs[2])

	// Unmount by mount path.
	umountReq = &UmountRequest{
		Identifier: ms[2].Path,
	}
	umountRes, err = g.Umount(umountReq)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if umountRes.MountID != mountIDs[2] {
		t.Errorf("want mount ID: %s; got %s", mountIDs[2], umountRes.MountID)
	}
	if umountRes.Mount != ms[2] || umountRes.MountID != mountIDs[2] {
		t.Errorf("want mount %s; got %s", ms[2], umountRes.Mount)
	}

	shouldAccessible(mountIDs[0])
	shouldNotExist(mountIDs[1])
	shouldNotExist(mountIDs[2])

	// Invalid identifier.
	invalidIDs := []string{
		"invalid",
		"00000000-0000-4000-0000-000000000000", // non -existing.
	}

	for _, invalidID := range invalidIDs {
		umountReq = &UmountRequest{
			Identifier: invalidID,
		}
		if umountRes, err = g.Umount(umountReq); err == nil {
			t.Fatalf("want err != nil for identifier == %q; got nil", invalidID)
		}
	}
}

func testAddMount(g *Group, id machine.ID, ms ...mount.Mount) (mountIDs mount.IDSlice, err error) {
	for _, m := range ms {
		req := &AddMountRequest{
			MountRequest: MountRequest{
				ID:    id,
				Mount: m,
			},
		}
		res, err := g.AddMount(req)
		if err != nil {
			return nil, err
		}

		mountIDs = append(mountIDs, res.MountID)
	}

	if len(mountIDs) == 0 {
		return nil, errors.New("no mounts added")
	}

	return mountIDs, nil
}
