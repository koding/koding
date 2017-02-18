package index_test

import (
	"fmt"
	"reflect"
	"sort"
	"testing"

	"koding/klient/machine/index"
)

func fixture() *index.Node {
	return &index.Node{
		Entry: index.NewEntry(0, 0),
		Sub: map[string]*index.Node{
			"addresses": {
				Entry: index.NewEntry(0, 0),
				Sub: map[string]*index.Node{
					"addresser.go": {
						Entry: index.NewEntry(714, 0),
					},
					"addresses.go": {
						Entry: index.NewEntry(2428, 0),
					},
					"addresses_test.go": {
						Entry: index.NewEntry(3095, 0),
					},
					"cached.go": {
						Entry: index.NewEntry(2036, 0),
					},
				},
			},
			"aliases": {
				Entry: index.NewEntry(0, 0),
				Sub: map[string]*index.Node{
					"aliaser.go": {
						Entry: index.NewEntry(596, 0),
					},
					"aliases.go": {
						Entry: index.NewEntry(3218, 0),
					},
					"aliases_test.go": {
						Entry: index.NewEntry(1831, 0),
					},
					"cached.go": {
						Entry: index.NewEntry(2196, 0),
					},
				},
			},
			"clients": {
				Entry: index.NewEntry(0, 0),
				Sub: map[string]*index.Node{
					"clients.go": {
						Entry: index.NewEntry(4003, 0),
					},
					"clients_test.go": {
						Entry: index.NewEntry(1783, 0),
					},
				},
			},
			"create.go": {
				Entry: index.NewEntry(3660, 0),
			},
			"create_test.go": {
				Entry: index.NewEntry(4582, 0),
			},
			"id.go": {
				Entry: index.NewEntry(1272, 0),
			},
			"id_test.go": {
				Entry: index.NewEntry(1979, 0),
			},
			"idset": {
				Entry: index.NewEntry(0, 0),
				Sub: map[string]*index.Node{
					"idset.go": {
						Entry: index.NewEntry(1288, 0),
					},
					"idset_test.go": {
						Entry: index.NewEntry(4231, 0),
					},
				},
			},
			"kite.go": {
				Entry: index.NewEntry(4152, 0),
			},
			"machinegroup.go": {
				Entry: index.NewEntry(6839, 0),
			},
			"machinegroup_test.go": {
				Entry: index.NewEntry(6592, 0),
			},
			"mount.go": {
				Entry: index.NewEntry(9346, 0),
			},
			"mount_test.go": {
				Entry: index.NewEntry(8824, 0),
			},
			"mounts": {
				Entry: index.NewEntry(0, 0),
				Sub: map[string]*index.Node{
					"cached.go": {
						Entry: index.NewEntry(2465, 0),
					},
					"mounter.go": {
						Entry: index.NewEntry(1000, 0),
					},
					"mounts.go": {
						Entry: index.NewEntry(4133, 0),
					},
					"mounts_test.go": {
						Entry: index.NewEntry(5330, 0),
					},
				},
			},
			"ssh.go": {
				Entry: index.NewEntry(2831, 0),
			},
			"ssh_test.go": {
				Entry: index.NewEntry(3567, 0),
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

			if nd.Entry.Size() != size {
				t.Fatalf("got %d, want %d", size, nd.Entry.Size())
			}
		})
	}
}

func TestNodeCount(t *testing.T) {
	cases := map[int64]int{
		-1:   32,
		0:    0,
		4000: 22,
		6000: 28,
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
		{"addresses/cached_test.go", 33},
		{"notify.go", 34},
		{"notify/notify.go", 36},
		{"proxy/fuse/fuse.go", 39},
		{"notify", 39},   // no-op
		{"notify/", 39},  // no-op
		{"/notify/", 39}, // no-op
		{"/notify", 39},  // no-op
	}

	root := fixture()
	entry := index.NewEntry(0xD, 0)

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

			if nd.Entry.Size() != entry.Size() {
				t.Fatalf("got %d, want %d", nd.Entry.Size(), entry.Size())
			}
		})
	}
}

func TestNodeDel(t *testing.T) {
	cases := []struct {
		name  string
		count int
	}{
		{"addresses/addresser.go", 31},
		{"addresses/", 27},
		{"aliases", 22},
		{"id.go", 21},
		{"id.go", 21},          // no-op
		{"nonexisting.go", 21}, // no-op
		{"/kite.go", 20},
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

	root.ForEach(func(name string, _ *index.Entry) {
		got = append(got, name)
	})

	sort.Strings(got)

	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %v, want %v", got, want)
	}
}
