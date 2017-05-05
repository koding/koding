package node_test

import (
	"testing"

	"koding/klient/machine/index/node"
)

func BenchmarkNodeLookup(b *testing.B) {
	const name = "/idset/idset_test.go"
	tree := testTree(fixData)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		tree.DoPath(name, func(_ node.Guard, n *node.Node) bool {
			if n.IsShadowed() {
				b.Fatalf("want %s to be present in tree", name)
			}

			return true
		})
	}
}

func BenchmarkNodeAdd(b *testing.B) {
	const name = "proxy/tmp/sync/fuse/fuse.go"
	entry := node.NewEntry(0xB, 0, node.RootInodeID)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		b.StopTimer()
		tree := testTree(fixData)
		b.StartTimer()

		tree.DoPath(name, node.Insert(entry))
	}
}

func BenchmarkNodeDel(b *testing.B) {
	const name = "addresses/addresser.go"

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		b.StopTimer()
		tree := testTree(fixData)
		b.StartTimer()

		tree.DoPath(name, node.Delete())
	}
}

func BenchmarkNodeForEach(b *testing.B) {
	tree := testTree(fixData)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		tree.DoPath("", node.WalkPath(func(nodePath string, _ node.Guard, _ *node.Node) {}))
	}
}
