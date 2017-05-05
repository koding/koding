package index_test

import (
	"bytes"
	"encoding/json"
	"flag"
	"testing"
	"time"

	"koding/klient/machine/index"
	"koding/klient/machine/index/node"
)

var repo = flag.String("repo", "", "")

func TestRepo(t *testing.T) {
	if *repo == "" {
		t.Skip("missing -repo path, skipping...")
	}

	start := time.Now()
	idx, err := index.NewIndexFiles(*repo, nil)
	if err != nil {
		t.Fatalf("NewIndexFiles()=%s", err)
	}
	end := time.Now()

	var buf bytes.Buffer

	if err := json.NewEncoder(&buf).Encode(idx); err != nil {
		t.Fatalf("Encode()=%s", err)
	}

	t.Logf("Index build time: %s", end.Sub(start))
	t.Logf("Index file count: %d", idx.Tree().Count())
	t.Logf("Index size: %.4f MiB", float64(buf.Len())/1024/1024)
}

func BenchmarkNodeLookup(b *testing.B) {
	const name = "/idset/idset_test.go"
	root := fixture()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if _, ok := root.Lookup(name); !ok {
			b.Fatalf("want %s to be present in root node", name)
		}
	}
}

func BenchmarkNodeAdd(b *testing.B) {
	const name = "proxy/tmp/sync/fuse/fuse.go"
	entry := node.NewEntry(0xB, 0, node.RootInodeID)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		b.StopTimer()
		root := fixture()
		b.StartTimer()

		root.Add(name, entry)
	}
}

func BenchmarkNodeDel(b *testing.B) {
	const name = "addresses/addresser.go"

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		b.StopTimer()
		root := fixture()
		b.StartTimer()

		root.Del(name)
	}
}

func BenchmarkNodeForEach(b *testing.B) {
	root := fixture()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		root.ForEach(func(name string, _ *node.Entry) {})
	}
}
