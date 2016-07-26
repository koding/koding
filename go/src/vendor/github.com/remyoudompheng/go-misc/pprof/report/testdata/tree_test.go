// +build ignore

// The purpose of this file is to generate a potentially very large
// heap profile. Run
//   go build -bench Tree -memprofile heap.prof -memprofilerate 1024 tree_test.go

package main

import (
	"math/rand"
	"testing"
)

type Node struct {
	Value       uint32
	Left, Right *Node
}

func InsertTree(t *Node, n uint32) *Node {
	if t == nil {
		return &Node{Value: n}
	}
      if t.Value == n {
            return t
      }
	newt := *t
	if n < t.Value {
		newt.Left = InsertTree(t.Left, n)
	} else {
		newt.Right = InsertTree(t.Right, n)
	}
	return &newt
}

func BenchmarkTree(b *testing.B) {
	var t *Node
	for i := 0; i < b.N; i++ {
		t = InsertTree(t, rand.Uint32())
	}
}
