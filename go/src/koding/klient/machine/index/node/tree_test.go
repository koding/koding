package node_test

import (
	"encoding/json"
	"reflect"
	"sort"
	"testing"

	"koding/klient/machine/index/node"
)

var fixData = map[string]int64{
	"addresses":                   0,
	"addresses/addresser.go":      714,
	"addresses/addresses.go":      2428,
	"addresses/addresses_test.go": 3095,
	"addresses/cached.go":         2036,
	"aliases":                     0,
	"aliases/aliaser.go":          596,
	"aliases/aliases.go":          3218,
	"aliases/aliases_test.go":     1831,
	"aliases/cached.go":           2196,
	"clients":                     0,
	"clients/clients.go":          4003,
	"clients/clients_test.go":     1783,
	"create.go":                   3660,
	"create_test.go":              4582,
	"id.go":                       1272,
	"id_test.go":                  1979,
	"idset":                       0,
	"idset/idset.go":              1288,
	"idset/idset_test.go":         4231,
	"empty":                       0,
	"kite.go":                     4152,
	"machinegroup.go":             6839,
	"machinegroup_test.go":        6592,
	"mount.go":                    9346,
	"mount_test.go":               8824,
	"mounts":                      0,
	"mounts/cached.go":            2465,
	"mounts/mounter.go":           1000,
	"mounts/mounts.go":            4133,
	"mounts/mounts_test.go":       5330,
	"ssh.go":                      2831,
	"ssh_test.go":                 3567,
}

func testTree(data map[string]int64) *node.Tree {
	var paths []string
	for path := range data {
		paths = append(paths, path)
	}

	sort.Strings(paths)

	tree := node.NewTree()
	for _, path := range paths {
		size := data[path]
		tree.DoPath(path, node.Insert(node.NewEntry(size, 0, 0)))
	}

	return tree
}

func TestTreeLookup(t *testing.T) {
	cases := map[string]int64{
		"/":                       0,
		"addresses":               0,
		"addresses/addresses.go":  2428,
		"machinegroup.go":         6839,
		"idset/idset_test.go":     4231,
		"/addresses":              0,
		"/addresses/addresses.go": 2428,
		"/machinegroup.go":        6839,
		"/idset/idset_test.go":    4231,
	}

	tree := testTree(fixData)

	for path, size := range cases {
		path, size := path, size // Capture range variables.
		t.Run(path, func(t *testing.T) {
			t.Parallel()

			tree.DoPath(path, func(_ node.Guard, n *node.Node) bool {
				if n.IsShadowed() {
					t.Fatalf("Lookup(%q) failed", path)
				}

				if es := n.Entry.File.Size; es != size {
					t.Errorf("got %d, want %d", size, es)
				}

				return true
			})
		})
	}
}

func TestTreeCount(t *testing.T) {
	cases := map[string]int{
		"":                       34,
		"/":                      34,
		"addresses":              5,
		"addresses/addresses.go": 1,
		"idset":                  3,
	}

	tree := testTree(fixData)

	for path, count := range cases {
		path, count := path, count // Capture range variables.
		t.Run(path, func(t *testing.T) {
			t.Parallel()

			var got int
			if tree.DoPath(path, node.Count(&got)); got != count {
				t.Errorf("got %d, want %d", got, count)
			}
		})
	}
}

func TestTreeDiskSize(t *testing.T) {
	cases := map[string]int64{
		"":                       93991,
		"/":                      93991,
		"/some/unknown/path":     0,
		"addresses/addresses.go": 2428,
		"idset":                  1288 + 4231,
	}

	tree := testTree(fixData)

	for path, size := range cases {
		path, size := path, size // Capture range variables.
		t.Run(path, func(t *testing.T) {
			t.Parallel()

			var got int64
			if tree.DoPath(path, node.DiskSize(&got)); got != size {
				t.Errorf("got %d, want %d", got, size)
			}
		})
	}
}

func TestTreeAdd(t *testing.T) {
	const finalCount = 61

	cases := map[string]struct{}{
		"addresses/cached_test.go": {},
		"notify.go":                {},
		"notify/notify.go":         {},
		"proxy/fuse/fuse.go":       {},
		"notify":                   {},
		"notify/":                  {},
		"/notify/":                 {},
		"/notify":                  {},
		"a/b/c/d/e/f/g/h/i/j":      {},
		"a/a/a/a/a/a/a/a/a/a/a":    {},
	}

	tree := testTree(fixData)

	// Run parallel test in group test since T object uses parallel results.
	t.Run("group", func(t *testing.T) {
		const funnySize = 0xD
		for path, _ := range cases {
			path := path // Capture range variable.
			t.Run(path, func(t *testing.T) {
				t.Parallel()

				tree.DoPath(path, node.Insert(node.NewEntry(funnySize, 0, 0)))
				tree.DoPath(path, func(_ node.Guard, n *node.Node) bool {
					if n.IsShadowed() {
						t.Fatalf("Lookup(%q) failed", path)
					}

					if size := n.Entry.File.Size; size != funnySize {
						t.Errorf("got %d, want %d", size, funnySize)
					}

					return true
				})
			})
		}
	})

	if count := tree.Count(); count != finalCount {
		t.Fatalf("got %d, want %d", count, finalCount)
	}
}

func TestTreeDel(t *testing.T) {
	const finalCount = 22

	cases := map[string]struct{}{
		"addresses/addresser.go": {},
		"addresses/":             {},
		"aliases":                {},
		"id.go":                  {},
		"/id.go":                 {},
		"nonexisting.go":         {},
		"/kite.go":               {},
	}

	tree := testTree(fixData)

	// Run parallel test in group test since T object uses parallel results.
	t.Run("group", func(t *testing.T) {
		for path, _ := range cases {
			path := path // Capture range variable.
			t.Run(path, func(t *testing.T) {
				t.Parallel()

				tree.DoPath(path, node.Delete())
			})
		}
	})

	if count := tree.Count(); count != finalCount {
		t.Fatalf("got %d, want %d", count, finalCount)
	}
}

func TestTreeForEach(t *testing.T) {
	want := []string{
		"",
		"addresses",
		"addresses/addresser.go",
		"addresses/addresses.go",
		"addresses/addresses_test.go",
		"addresses/cached.go",
		"aliases",
		"aliases/aliaser.go",
		"aliases/aliases.go",
		"aliases/aliases_test.go",
		"aliases/cached.go",
		"clients",
		"clients/clients.go",
		"clients/clients_test.go",
		"create.go",
		"create_test.go",
		"empty",
		"id.go",
		"id_test.go",
		"idset",
		"idset/idset.go",
		"idset/idset_test.go",
		"kite.go",
		"machinegroup.go",
		"machinegroup_test.go",
		"mount.go",
		"mount_test.go",
		"mounts",
		"mounts/cached.go",
		"mounts/mounter.go",
		"mounts/mounts.go",
		"mounts/mounts_test.go",
		"ssh.go",
		"ssh_test.go",
	}

	var got []string
	tree := testTree(fixData)

	tree.DoPath("", node.WalkPath(func(nodePath string, _ node.Guard, _ *node.Node) {
		got = append(got, nodePath)
	}))

	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %v, want %v", got, want)
	}
}

func TestTreeMarshalJSON(t *testing.T) {
	var (
		treePaths, gotPaths     []string
		treeEntries, gotEntries []*node.Entry
	)

	tree := testTree(fixData)
	tree.DoPath("", node.WalkPath(func(nodePath string, _ node.Guard, n *node.Node) {
		treePaths = append(treePaths, nodePath)
		treeEntries = append(treeEntries, n.Entry)
	}))

	data, err := json.Marshal(tree)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	got := &node.Tree{}
	if err := json.Unmarshal(data, got); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	got.DoPath("", node.WalkPath(func(nodePath string, _ node.Guard, n *node.Node) {
		gotPaths = append(gotPaths, nodePath)
		gotEntries = append(gotEntries, n.Entry)
	}))

	if !reflect.DeepEqual(treePaths, gotPaths) {
		t.Errorf("want:\n%#v\ngot\n%#v\n", tree, got)
	}

	if !reflect.DeepEqual(treeEntries, gotEntries) {
		t.Errorf("want:\n%#v\ngot\n%#v\n", treeEntries, gotEntries)
	}
}
