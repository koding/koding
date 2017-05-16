package index_test

import (
	"encoding/json"
	"sort"
	"testing"

	"koding/klient/machine/index"
	"koding/klient/machine/index/indextest"
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
			Op: indextest.WriteFile("d/test.bin", 40*1024),
			Changes: index.ChangeSlice{
				index.NewChange("d/test.bin", index.PriorityLow, index.ChangeMetaAdd),
			},
		},
		"add dir": {
			Op: indextest.AddDir("e"),
			Changes: index.ChangeSlice{
				index.NewChange("e", index.PriorityLow, index.ChangeMetaAdd),
			},
		},
		"remove file": {
			Op: indextest.RmAllFile("c/cb.bin"),
			Changes: index.ChangeSlice{
				index.NewChange("c/cb.bin", index.PriorityLow, index.ChangeMetaRemote|index.ChangeMetaAdd),
			},
		},
		"remove dir": {
			Op: indextest.RmAllFile("c"),
			Changes: index.ChangeSlice{
				index.NewChange("c", index.PriorityLow, index.ChangeMetaRemote|index.ChangeMetaAdd),
				index.NewChange("c/ca.txt", index.PriorityLow, index.ChangeMetaRemote|index.ChangeMetaAdd),
				index.NewChange("c/cb.bin", index.PriorityLow, index.ChangeMetaRemote|index.ChangeMetaAdd),
			},
			Branch: "c/",
		},
		"rename file": {
			Op: indextest.MvFile("b.bin", "c/cc.bin"),
			Changes: index.ChangeSlice{
				index.NewChange("b.bin", index.PriorityLow, index.ChangeMetaRemote|index.ChangeMetaAdd),
				index.NewChange("c/cc.bin", index.PriorityLow, index.ChangeMetaAdd),
			},
		},
		"write file": {
			Op: indextest.WriteFile("b.bin", 1024),
			Changes: index.ChangeSlice{
				index.NewChange("b.bin", index.PriorityMedium, index.ChangeMetaUpdate),
			},
		},
		"chmod file": {
			Op: indextest.ChmodFile("d/dc/dca.txt", 0600),
			Changes: index.ChangeSlice{
				index.NewChange("d/dc/dca.txt", index.PriorityMedium, index.ChangeMetaUpdate),
			},
			Branch: "d/dc",
		},
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			root, clean, err := indextest.GenerateTree(filetree)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}
			defer clean()

			idx, err := index.NewIndexFiles(root, nil)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			if err := test.Op(root); err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			// Synchronize underlying file-system.
			indextest.Sync()

			cs, err := idx.MergeBranch(root, test.Branch, nil)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			sort.Sort(cs)
			if len(cs) != len(test.Changes) {
				t.Fatalf("want index.Changes count = %d; got %d", len(test.Changes), len(cs))
			}

			// Copy time from result to tests.
			for i, tc := range test.Changes {
				if cs[i].Path() != tc.Path() {
					t.Errorf("want index.Change path = %q; got %q", tc.Path(), cs[i].Path())
				}
				if cm, tm := cs[i].Meta(), tc.Meta(); cm != tm {
					t.Errorf("want index.Change meta = %s; got %s", tm.String(), cm.String())
				}
				if cp, tp := cs[i].Priority(), tc.Priority(); cp != tp {
					t.Errorf("want index.Change priority = %s; got %s", tp.String(), cp.String())
				}
			}

			for _, c := range cs {
				idx.Sync(root, c)
			}

			if cs, err = idx.MergeBranch(root, test.Branch, nil); err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}
			if len(cs) != 0 {
				t.Errorf("want no index.Changes after sync; got %v", cs)
			}
		})
	}
}

func TestIndexJSON(t *testing.T) {
	root, clean, err := indextest.GenerateTree(filetree)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()

	idx, err := index.NewIndexFiles(root, nil)
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

	cs, err := idx.Merge(root, nil)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if len(cs) != 0 {
		t.Errorf("want no changes after merge; got %v", cs)
	}
}
