package index_test

import (
	"encoding/json"
	"io"
	"io/ioutil"
	"math/rand"
	"os"
	"path/filepath"
	"sort"
	"testing"
	"time"

	"koding/klient/machine/index"
)

// filetree defines a simple directory structure that will be created for test
// purposes. The values of this map stores file sizes.
var filetree = map[string]int64{
	"a.txt":        128,
	"b.bin":        300 * 1024,
	"c/":           0,
	"c/ca.txt":     2 * 1024,
	"c/cb.bin":     1024 * 1024,
	"d/":           0,
	"d/da.txt":     5 * 1024,
	"d/db.txt":     256,
	"d/dc/":        0,
	"d/dc/dca.txt": 3 * 1024,
	"d/dc/dcb.txt": 1024,
}

func TestIndex(t *testing.T) {
	tests := map[string]struct {
		Op      func(string) error
		Changes index.ChangeSlice
		Branch  string
	}{
		"add file": {
			Op: writeFile("d/test.bin", 40*1024),
			Changes: index.ChangeSlice{
				index.NewChange("d", index.ChangeMetaUpdate),
				index.NewChange("d/test.bin", index.ChangeMetaAdd),
			},
		},
		"add dir": {
			Op: addDir("e"),
			Changes: index.ChangeSlice{
				index.NewChange("e", index.ChangeMetaAdd),
			},
		},
		"remove file": {
			Op: rmAllFile("c/cb.bin"),
			Changes: index.ChangeSlice{
				index.NewChange("c", index.ChangeMetaUpdate),
				index.NewChange("c/cb.bin", index.ChangeMetaRemove),
			},
		},
		"remove dir": {
			Op: rmAllFile("c"),
			Changes: index.ChangeSlice{
				index.NewChange("c", index.ChangeMetaRemove),
				index.NewChange("c/ca.txt", index.ChangeMetaRemove),
				index.NewChange("c/cb.bin", index.ChangeMetaRemove),
			},
			Branch: "c/",
		},
		"rename file": {
			Op: mvFile("b.bin", "c/cc.bin"),
			Changes: index.ChangeSlice{
				index.NewChange("b.bin", index.ChangeMetaRemove),
				index.NewChange("c", index.ChangeMetaUpdate),
				index.NewChange("c/cc.bin", index.ChangeMetaAdd),
			},
		},
		"write file": {
			Op: writeFile("b.bin", 1024),
			Changes: index.ChangeSlice{
				index.NewChange("b.bin", index.ChangeMetaUpdate),
			},
		},
		"chmod file": {
			Op: chmodFile("d/dc/dca.txt", 0766),
			Changes: index.ChangeSlice{
				index.NewChange("d/dc/dca.txt", index.ChangeMetaUpdate),
			},
			Branch: "d/dc",
		},
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			root, clean, err := generateTree()
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}
			defer clean()

			idx, err := index.NewIndexFiles(root)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			if err := test.Op(root); err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			// Synchronize underlying file-system.
			Sync()

			cs := idx.CompareBranch(test.Branch, root)
			sort.Sort(cs)
			if len(cs) != len(test.Changes) {
				t.Fatalf("want index.Changes count = %d; got %d", len(test.Changes), len(cs))
			}

			// Copy time from result to tests.
			for i, tc := range test.Changes {
				if cs[i].Path() != tc.Path() {
					t.Errorf("want index.Change path = %q; got %q", tc.Path(), cs[i].Path())
				}
				if cs[i].Meta() != tc.Meta() {
					t.Errorf("want index.Change meta = %bb; got %bb", tc.Meta, cs[i].Meta)
				}
			}

			idx.Apply(root, cs)
			if cs = idx.CompareBranch(test.Branch, root); len(cs) != 0 {
				t.Errorf("want no index.Changes after apply; got %#v", cs)
			}
		})
	}
}

func TestIndexCount(t *testing.T) {
	tests := map[string]struct {
		MaxSize  int64
		Expected int
	}{
		"all items": {
			MaxSize:  -1,
			Expected: 11,
		},
		"less than 100kiB": {
			MaxSize:  100 * 1024,
			Expected: 9,
		},
		"zero": {
			MaxSize:  0,
			Expected: 0,
		},
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			root, clean, err := generateTree()
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}
			defer clean()

			idx, err := index.NewIndexFiles(root)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			if count := idx.Count(test.MaxSize); count != test.Expected {
				t.Errorf("want count = %d; got %d", test.Expected, count)
			}
		})
	}
}

func TestIndexJSON(t *testing.T) {
	root, clean, err := generateTree()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	idx, err := index.NewIndexFiles(root)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	data, err := json.Marshal(idx)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	idx = index.NewIndex()
	if err := json.Unmarshal(data, idx); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if cs := idx.Compare(root); len(cs) != 0 {
		t.Errorf("want no changes after apply; got %#v", cs)
	}
}

func generateTree() (root string, clean func(), err error) {
	root, err = ioutil.TempDir("", "mount.index")
	if err != nil {
		return "", nil, err
	}
	clean = func() { os.RemoveAll(root) }

	for file, size := range filetree {
		if err := addDir(file)(root); err != nil {
			clean()
			return "", nil, err
		}
		if err := writeFile(file, size)(root); err != nil {
			clean()
			return "", nil, err
		}
	}

	return root, clean, nil
}

func addDir(file string) func(string) error {
	return func(root string) error {
		defer Sync()

		dir := filepath.Join(root, filepath.FromSlash(file))
		if filepath.Ext(dir) != "" {
			dir = filepath.Dir(dir)
		}

		return os.MkdirAll(dir, 0777)
	}
}

func writeFile(file string, size int64) func(string) error {
	return func(root string) error {
		defer Sync()

		if filepath.Ext(file) == "" {
			return nil
		}

		lr := io.LimitReader(rand.New(rand.NewSource(time.Now().UnixNano())), size)
		content, err := ioutil.ReadAll(lr)
		if err != nil {
			return err
		}

		file := filepath.Join(root, filepath.FromSlash(file))
		return ioutil.WriteFile(file, content, 0666)
	}
}

func rmAllFile(file string) func(string) error {
	return func(root string) error {
		defer Sync()

		return os.RemoveAll(filepath.Join(root, filepath.FromSlash(file)))
	}
}

func mvFile(oldpath, newpath string) func(string) error {
	return func(root string) error {
		defer Sync()

		var (
			oldpath = filepath.Join(root, filepath.FromSlash(oldpath))
			newpath = filepath.Join(root, filepath.FromSlash(newpath))
		)

		return os.Rename(oldpath, newpath)
	}
}

func chmodFile(file string, mode os.FileMode) func(string) error {
	return func(root string) error {
		defer Sync()

		return os.Chmod(filepath.Join(root, filepath.FromSlash(file)), mode)
	}
}
