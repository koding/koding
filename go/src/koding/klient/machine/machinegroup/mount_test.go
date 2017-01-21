package machinegroup

import (
	"reflect"
	"testing"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/client/clienttest"
	"koding/klient/machine/index"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/mounttest"
	"koding/klient/machine/mount/sync"
)

func TestHeadMount(t *testing.T) {
	var (
		builder = clienttest.NewBuilder(nil)
		id      = machine.ID("serv")
	)

	wd, m, clean, err := mounttest.MountDirs("")
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
	createReq := &CreateRequest{
		Addresses: map[machine.ID][]machine.Addr{
			id: {clienttest.TurnOnAddr()},
		},
	}
	if _, err := g.Create(createReq); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if err := builder.WaitForBuild(time.Second); err != nil {
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
	idx, err := index.NewIndexFiles(m.RemotePath)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if resc, idxc := headMountRes.AllCount, idx.Count(-1); resc != idxc {
		t.Errorf("want file count = %d; got %d", idxc, resc)
	}
	if resds, idxds := headMountRes.AllDiskSize, idx.DiskSize(-1); resds != idxds {
		t.Errorf("want disk size = %d; got %d", idxds, resds)
	}
}

func TestAddMount(t *testing.T) {
	var (
		builder = clienttest.NewBuilder(nil)
		id      = machine.ID("serv")
	)

	wd, m, clean, err := mounttest.MountDirs("")
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
	createReq := &CreateRequest{
		Addresses: map[machine.ID][]machine.Addr{
			id: {clienttest.TurnOnAddr()},
		},
	}
	if _, err := g.Create(createReq); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if err := builder.WaitForBuild(time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Add testing mount.
	addMountReq := &AddMountRequest{
		MountRequest{
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
	wd, mA, cleanA, err := mounttest.MountDirs("")
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer cleanA()

	_, mB, cleanB, err := mounttest.MountDirs(wd)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer cleanB()

	g, err := New(testOptions(wd, builder))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	// Add two connected remote machines.
	createReq := &CreateRequest{
		Addresses: map[machine.ID][]machine.Addr{
			idA: {clienttest.TurnOnAddr()},
			idB: {clienttest.TurnOnAddr()},
		},
	}
	createRes, err := g.Create(createReq)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	for i := 0; i < len(createReq.Addresses); i++ {
		if err := builder.WaitForBuild(time.Second); err != nil {
			t.Fatalf("want err = nil; got %v", err)
		}
	}

	// Add testing mounts to A machine.
	var mountIDs []mount.ID
	for _, m := range []mount.Mount{mA, mB} {
		addMountReq := &AddMountRequest{
			MountRequest{
				ID:    idA,
				Mount: m,
			},
		}
		addMountRes, err := g.AddMount(addMountReq)
		if err != nil {
			t.Fatalf("want err = nil; got %v", err)
		}

		mountIDs = append(mountIDs, addMountRes.MountID)
	}

	tests := map[string]struct {
		LMReq         ListMountRequest
		ConcatIDsInfo map[string]sync.Info
	}{
		"all mounts": {
			ConcatIDsInfo: map[string]sync.Info{
				createRes.Aliases[idA] + string(mountIDs[0]): {
					ID:    mountIDs[0],
					Mount: mA,
				},
				createRes.Aliases[idA] + string(mountIDs[1]): {
					ID:    mountIDs[1],
					Mount: mB,
				},
			},
		},
		"all mounts from machine A": {
			LMReq: ListMountRequest{
				ID: idA,
			},
			ConcatIDsInfo: map[string]sync.Info{
				createRes.Aliases[idA] + string(mountIDs[0]): {
					ID:    mountIDs[0],
					Mount: mA,
				},
				createRes.Aliases[idA] + string(mountIDs[1]): {
					ID:    mountIDs[1],
					Mount: mB,
				},
			},
		},
		"all mounts from machine B": {
			LMReq: ListMountRequest{
				ID: idB,
			},
			ConcatIDsInfo: map[string]sync.Info{},
		},
		"filter by mount ID": {
			LMReq: ListMountRequest{
				MountID: mountIDs[1],
			},
			ConcatIDsInfo: map[string]sync.Info{
				createRes.Aliases[idA] + string(mountIDs[1]): {
					ID:    mountIDs[1],
					Mount: mB,
				},
			},
		},
		"filter by mount ID and machine A": {
			LMReq: ListMountRequest{
				ID:      idA,
				MountID: mountIDs[0],
			},
			ConcatIDsInfo: map[string]sync.Info{
				createRes.Aliases[idA] + string(mountIDs[0]): {
					ID:    mountIDs[0],
					Mount: mA,
				},
			},
		},
		"filter by mount ID and machine B": {
			LMReq: ListMountRequest{
				ID:      idB,
				MountID: mountIDs[0],
			},
			ConcatIDsInfo: map[string]sync.Info{},
		},
		"unknown machine ID": {
			LMReq: ListMountRequest{
				ID:      idB,
				MountID: mountIDs[0],
			},
			ConcatIDsInfo: map[string]sync.Info{},
		},
		"unknown mount ID": {
			LMReq: ListMountRequest{
				ID:      idB,
				MountID: mountIDs[0],
			},
			ConcatIDsInfo: map[string]sync.Info{},
		},
	}

	for name, test := range tests {
		t.Run(name, func(t *testing.T) {
			listMountRes, err := g.ListMount(&test.LMReq)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			if listMountRes.Mounts == nil {
				t.Fatalf("want mount list response != nil; got nil")
			}

			// Prepare results.
			concatIDsRes, n := make(map[string]sync.Info), 0
			for alias, infos := range listMountRes.Mounts {
				for _, info := range infos {
					concatIDsRes[alias+string(info.ID)] = sync.Info{
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
