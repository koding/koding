package mount

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"reflect"
	"testing"

	"koding/klient/machine/client"
	"koding/klient/machine/client/testutil"
)

func TestSyncAdd(t *testing.T) {
	wd, remotePath, clean, err := testMountDirs()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	// Add new mount.
	mountID := MakeID()
	s, m, err := testSyncWithMount(mountID, wd, remotePath)
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
	if _, err := tempFile(remotePath); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if _, err := tempFile(filepath.Join(mountWD, "data")); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// New add of existing mount.
	if s, _, err = testSyncWithMount(mountID, wd, remotePath); err != nil {
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
	wd, remotePath, clean, err := testMountDirs()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	// Add new mount.
	mountID := MakeID()
	s, _, err := testSyncWithMount(mountID, wd, remotePath)
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

func testSyncWithMount(mountID ID, wd, remotePath string) (s *Sync, m Mount, err error) {
	opts := SyncOpts{
		ClientFunc: func(ID) (client.Client, error) {
			return testutil.NewClient(), nil
		},
		WorkDir: wd,
	}

	s, err = NewSync(opts)
	if err != nil {
		return nil, Mount{}, err
	}

	// Add new mount.
	m = Mount{
		Path:       "some/path",
		RemotePath: remotePath,
	}

	return s, m, s.Add(mountID, m)
}

func testMountDirs() (wd, remotePath string, clean func(), err error) {
	// Create path to be mounted.
	remotePath, rpClean, err := tempDir()
	if err != nil {
		return "", "", nil, err
	}

	// Put a sample file into remote directory.
	if _, err := tempFile(remotePath); err != nil {
		rpClean()
		return "", "", nil, err
	}

	wd, wdClean, err := tempDir()
	if err != nil {
		rpClean()
		return "", "", nil, err
	}

	clean = func() {
		rpClean()
		wdClean()
	}

	return wd, remotePath, clean, nil
}

func tempDir() (root string, clean func(), err error) {
	root, err = ioutil.TempDir("", "mount.sync")
	if err != nil {
		return "", nil, err
	}

	return root, func() { os.RemoveAll(root) }, nil
}

func tempFile(root string) (string, error) {
	f, err := ioutil.TempFile(root, "sync")
	if err != nil {
		return "", nil
	}
	defer f.Close()

	if _, err := f.WriteString("sample content"); err != nil {
		return "", err
	}

	return f.Name(), nil
}
