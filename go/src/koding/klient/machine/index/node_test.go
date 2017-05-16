package index_test

import (
	"encoding/json"
	"fmt"
	"reflect"
	"sort"
	"testing"

	"koding/klient/machine/index"
	"koding/klient/machine/index/node"
)

func fixture() *index.Node {
	return &index.Node{
		Entry: node.NewEntry(0, 0, 0),
		Sub: map[string]*index.Node{
			"addresses": {
				Entry: node.NewEntry(0, 0, 0),
				Sub: map[string]*index.Node{
					"addresser.go": {
						Entry: node.NewEntry(714, 0, 0),
						Sub:   map[string]*index.Node{},
					},
					"addresses.go": {
						Entry: node.NewEntry(2428, 0, 0),
						Sub:   map[string]*index.Node{},
					},
					"addresses_test.go": {
						Entry: node.NewEntry(3095, 0, 0),
						Sub:   map[string]*index.Node{},
					},
					"cached.go": {
						Entry: node.NewEntry(2036, 0, 0),
						Sub:   map[string]*index.Node{},
					},
				},
			},
			"aliases": {
				Entry: node.NewEntry(0, 0, 0),
				Sub: map[string]*index.Node{
					"aliaser.go": {
						Entry: node.NewEntry(596, 0, 0),
						Sub:   map[string]*index.Node{},
					},
					"aliases.go": {
						Entry: node.NewEntry(3218, 0, 0),
						Sub:   map[string]*index.Node{},
					},
					"aliases_test.go": {
						Entry: node.NewEntry(1831, 0, 0),
						Sub:   map[string]*index.Node{},
					},
					"cached.go": {
						Entry: node.NewEntry(2196, 0, 0),
						Sub:   map[string]*index.Node{},
					},
				},
			},
			"clients": {
				Entry: node.NewEntry(0, 0, 0),
				Sub: map[string]*index.Node{
					"clients.go": {
						Entry: node.NewEntry(4003, 0, 0),
						Sub:   map[string]*index.Node{},
					},
					"clients_test.go": {
						Entry: node.NewEntry(1783, 0, 0),
						Sub:   map[string]*index.Node{},
					},
				},
			},
			"create.go": {
				Entry: node.NewEntry(3660, 0, 0),
				Sub:   map[string]*index.Node{},
			},
			"create_test.go": {
				Entry: node.NewEntry(4582, 0, 0),
				Sub:   map[string]*index.Node{},
			},
			"id.go": {
				Entry: node.NewEntry(1272, 0, 0),
				Sub:   map[string]*index.Node{},
			},
			"id_test.go": {
				Entry: node.NewEntry(1979, 0, 0),
				Sub:   map[string]*index.Node{},
			},
			"idset": {
				Entry: node.NewEntry(0, 0, 0),
				Sub: map[string]*index.Node{
					"idset.go": {
						Entry: node.NewEntry(1288, 0, 0),
						Sub:   map[string]*index.Node{},
					},
					"idset_test.go": {
						Entry: node.NewEntry(4231, 0, 0),
						Sub:   map[string]*index.Node{},
					},
				},
			},
			"empty": {
				Entry: node.NewEntry(0, 0, 0),
				Sub:   map[string]*index.Node{},
			},
			"kite.go": {
				Entry: node.NewEntry(4152, 0, 0),
				Sub:   map[string]*index.Node{},
			},
			"machinegroup.go": {
				Entry: node.NewEntry(6839, 0, 0),
				Sub:   map[string]*index.Node{},
			},
			"machinegroup_test.go": {
				Entry: node.NewEntry(6592, 0, 0),
				Sub:   map[string]*index.Node{},
			},
			"mount.go": {
				Entry: node.NewEntry(9346, 0, 0),
				Sub:   map[string]*index.Node{},
			},
			"mount_test.go": {
				Entry: node.NewEntry(8824, 0, 0),
				Sub:   map[string]*index.Node{},
			},
			"mounts": {
				Entry: node.NewEntry(0, 0, 0),
				Sub: map[string]*index.Node{
					"cached.go": {
						Entry: node.NewEntry(2465, 0, 0),
						Sub:   map[string]*index.Node{},
					},
					"mounter.go": {
						Entry: node.NewEntry(1000, 0, 0),
						Sub:   map[string]*index.Node{},
					},
					"mounts.go": {
						Entry: node.NewEntry(4133, 0, 0),
						Sub:   map[string]*index.Node{},
					},
					"mounts_test.go": {
						Entry: node.NewEntry(5330, 0, 0),
						Sub:   map[string]*index.Node{},
					},
				},
			},
			"ssh.go": {
				Entry: node.NewEntry(2831, 0, 0),
				Sub:   map[string]*index.Node{},
			},
			"ssh_test.go": {
				Entry: node.NewEntry(3567, 0, 0),
				Sub:   map[string]*index.Node{},
			},
		},
	}
}

func TestNodeLookup(t *testing.T) {
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

	root := fixture()

	for name, size := range cases {
		t.Run(name, func(t *testing.T) {
			nd, ok := root.Lookup(name)
			if !ok {
				t.Fatalf("Lookup(%q) failed", name)
			}

			if nd.Entry.File.Size != size {
				t.Fatalf("got %d, want %d", size, nd.Entry.File.Size)
			}
		})
	}
}

func TestNodeCount(t *testing.T) {
	cases := map[int64]int{
		-1:   34,
		0:    0,
		4000: 24,
		6000: 30,
	}

	root := fixture()

	for maxsize, count := range cases {
		t.Run(fmt.Sprintf("maxsize %d", maxsize), func(t *testing.T) {
			got := root.Count(maxsize)

			if got != count {
				t.Fatalf("got %d, want %d", got, count)
			}
		})
	}
}

func TestNodeDiskSize(t *testing.T) {
	cases := map[int64]int64{
		-1:   93991,
		0:    0,
		4000: 35959,
		6000: 62390,
	}

	root := fixture()

	for maxsize, size := range cases {
		t.Run(fmt.Sprintf("maxsize %d", maxsize), func(t *testing.T) {
			got := root.DiskSize(maxsize)

			if got != size {
				t.Fatalf("got %d, want %d", got, size)
			}
		})
	}
}

func TestNodeAdd(t *testing.T) {
	cases := []struct {
		name  string
		count int
	}{
		{"addresses/cached_test.go", 35},
		{"notify.go", 36},
		{"notify/notify.go", 38},
		{"proxy/fuse/fuse.go", 41},
		{"notify", 41},   // no-op
		{"notify/", 41},  // no-op
		{"/notify/", 41}, // no-op
		{"/notify", 41},  // no-op
	}

	root := fixture()
	entry := node.NewEntry(0xD, 0, node.RootInodeID)

	for _, cas := range cases {
		t.Run(cas.name, func(t *testing.T) {
			root.Add(cas.name, entry)

			nd, ok := root.Lookup(cas.name)
			if !ok {
				t.Fatalf("Lookup(%q) failed", cas.name)
			}

			count := root.Count(-1)

			if count != cas.count {
				t.Fatalf("got %d, want %d", count, cas.count)
			}

			if nd.Entry.File.Size != entry.File.Size {
				t.Fatalf("got %d, want %d", nd.Entry.File.Size, entry.File.Size)
			}
		})
	}
}

func TestNodeDel(t *testing.T) {
	cases := []struct {
		name  string
		count int
	}{
		{"addresses/addresser.go", 33},
		{"addresses/", 29},
		{"aliases", 24},
		{"id.go", 23},
		{"id.go", 23},          // no-op
		{"nonexisting.go", 23}, // no-op
		{"/kite.go", 22},
	}

	root := fixture()

	for _, cas := range cases {
		t.Run(cas.name, func(t *testing.T) {
			root.Del(cas.name)

			if _, ok := root.Lookup(cas.name); ok {
				t.Fatalf("%q was not deleted", cas.name)
			}

			count := root.Count(-1)

			if count != cas.count {
				t.Fatalf("got %d, want %d", count, cas.count)
			}
		})
	}
}

func TestNodeForEach(t *testing.T) {
	root := fixture()

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

	root.ForEach(func(name string, _ *node.Entry) {
		got = append(got, name)
	})

	sort.Strings(got)

	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %v, want %v", got, want)
	}
}

func TestNodeMarshalJSON(t *testing.T) {
	root := fixture()

	data, err := json.Marshal(root)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	nd := &index.Node{}
	if err := json.Unmarshal(data, nd); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if !reflect.DeepEqual(root, nd) {
		t.Fatalf("want:\n%#v\ngot\n%#v\n", root, nd)
	}
}

func TestNodeToTree(t *testing.T) {
	var gotNode, gotTree []string

	root := fixture()
	root.ForEach(func(name string, _ *node.Entry) {
		gotNode = append(gotNode, name)
	})

	sort.Strings(gotNode)

	tree := root.ToTree()
	tree.DoPath("", node.WalkPath(func(nodePath string, _ node.Guard, _ *node.Node) {
		gotTree = append(gotTree, nodePath)
	}))

	if !reflect.DeepEqual(gotTree, gotNode) {
		t.Fatalf("want:\n%#v\ngot\n%#v\n", gotNode, gotTree)
	}
}
