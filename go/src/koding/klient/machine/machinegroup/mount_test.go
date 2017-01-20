package machinegroup

import (
	"testing"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/client/clienttest"
	"koding/klient/machine/index"
	"koding/klient/machine/mount/mounttest"
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
