package index

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCachedIndexCreate(t *testing.T) {
	tempDir, cleanTempDir, err := makeTempDir()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer cleanTempDir()

	root, clean, err := generateTree()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	c := &Cached{TempDir: tempDir}
	idx, err := c.GetCachedIndex(root)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Check index integrity.
	count, diskSize, err := c.HeadCachedIndex(root)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if n := idx.Count(-1); count != n {
		t.Errorf("want %d entries, got %d", n, count)
	}
	if n := idx.DiskSize(-1); diskSize != n {
		t.Errorf("want size = %d bytes, got %d", n, diskSize)
	}

	// Cache should reuse existing index.
	dirnames, idxs, err := tmpDirInfo(tempDir())
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if l := len(dirnames); l != 1 {
		t.Errorf("want 1 temp directory; got %d", l)
	}
	if l := len(idxs); l != 1 {
		t.Errorf("want 1 index file; got %d", l)
	}
}

func TestCahcedIndexUpdated(t *testing.T) {
	tempDir, cleanTempDir, err := makeTempDir()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer cleanTempDir()

	root, clean, err := generateTree()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	c := &Cached{TempDir: tempDir}
	idx, err := c.GetCachedIndex(root)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if err := writeFile("new_file.txt", 1024)(root); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Should update and return new index.
	idx2, err := c.GetCachedIndex(root)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if count, n := idx.Count(-1)+1, idx2.Count(-1); count != n {
		t.Errorf("want %d entries; got %d", count, n)
	}
	if diskSize, n := idx.DiskSize(-1)+1024, idx2.DiskSize(-1); diskSize > n {
		t.Errorf("want at least %d B of disk size; got %d B", diskSize, n)
	}

	// Cache should reuse existing index.
	dirnames, idxs, err := tmpDirInfo(tempDir())
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if l := len(dirnames); l != 1 {
		t.Errorf("want 1 temp directory; got %d", l)
	}
	if l := len(idxs); l != 1 {
		t.Errorf("want 1 index file; got %d", l)
	}
}

func makeTempDir() (tempDir func() string, clean func(), err error) {
	dirname, err := ioutil.TempDir("", "mount.cache")
	if err != nil {
		return nil, nil, err
	}

	clean = func() { os.RemoveAll(dirname) }
	tempDir = func() string { return dirname }

	return
}

func tmpDirInfo(tempDir string) (dirnames, idxs []string, err error) {
	walkFn := func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}

		dir, file := filepath.Split(path)
		if info.IsDir() && strings.HasPrefix(file, tempIndexDirPrefix) {
			dirnames = append(dirnames, path)
		}

		if strings.HasPrefix(filepath.Base(dir), tempIndexDirPrefix) {
			if filepath.Join(tempDir, filepath.Base(dir), file) != path {
				return nil
			}

			idxs = append(idxs, path)
		}

		return nil
	}

	if err := filepath.Walk(tempDir, walkFn); err != nil {
		return nil, nil, err
	}

	return dirnames, idxs, nil
}
