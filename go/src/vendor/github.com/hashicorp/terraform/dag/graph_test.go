package dag

import (
	"fmt"
	"strings"
	"testing"
)

func TestGraph_empty(t *testing.T) {
	var g Graph
	g.Add(1)
	g.Add(2)
	g.Add(3)

	actual := strings.TrimSpace(g.String())
	expected := strings.TrimSpace(testGraphEmptyStr)
	if actual != expected {
		t.Fatalf("bad: %s", actual)
	}
}

func TestGraph_basic(t *testing.T) {
	var g Graph
	g.Add(1)
	g.Add(2)
	g.Add(3)
	g.Connect(BasicEdge(1, 3))

	actual := strings.TrimSpace(g.String())
	expected := strings.TrimSpace(testGraphBasicStr)
	if actual != expected {
		t.Fatalf("bad: %s", actual)
	}
}

func TestGraph_remove(t *testing.T) {
	var g Graph
	g.Add(1)
	g.Add(2)
	g.Add(3)
	g.Connect(BasicEdge(1, 3))
	g.Remove(3)

	actual := strings.TrimSpace(g.String())
	expected := strings.TrimSpace(testGraphRemoveStr)
	if actual != expected {
		t.Fatalf("bad: %s", actual)
	}
}

func TestGraph_replace(t *testing.T) {
	var g Graph
	g.Add(1)
	g.Add(2)
	g.Add(3)
	g.Connect(BasicEdge(1, 2))
	g.Connect(BasicEdge(2, 3))
	g.Replace(2, 42)

	actual := strings.TrimSpace(g.String())
	expected := strings.TrimSpace(testGraphReplaceStr)
	if actual != expected {
		t.Fatalf("bad: %s", actual)
	}
}

func TestGraph_replaceSelf(t *testing.T) {
	var g Graph
	g.Add(1)
	g.Add(2)
	g.Add(3)
	g.Connect(BasicEdge(1, 2))
	g.Connect(BasicEdge(2, 3))
	g.Replace(2, 2)

	actual := strings.TrimSpace(g.String())
	expected := strings.TrimSpace(testGraphReplaceSelfStr)
	if actual != expected {
		t.Fatalf("bad: %s", actual)
	}
}

// This tests that connecting edges works based on custom Hashcode
// implementations for uniqueness.
func TestGraph_hashcode(t *testing.T) {
	var g Graph
	g.Add(&hashVertex{code: 1})
	g.Add(&hashVertex{code: 2})
	g.Add(&hashVertex{code: 3})
	g.Connect(BasicEdge(
		&hashVertex{code: 1},
		&hashVertex{code: 3}))

	actual := strings.TrimSpace(g.String())
	expected := strings.TrimSpace(testGraphBasicStr)
	if actual != expected {
		t.Fatalf("bad: %s", actual)
	}
}

func TestGraphHasVertex(t *testing.T) {
	var g Graph
	g.Add(1)

	if !g.HasVertex(1) {
		t.Fatal("should have 1")
	}
	if g.HasVertex(2) {
		t.Fatal("should not have 2")
	}
}

func TestGraphHasEdge(t *testing.T) {
	var g Graph
	g.Add(1)
	g.Add(2)
	g.Connect(BasicEdge(1, 2))

	if !g.HasEdge(BasicEdge(1, 2)) {
		t.Fatal("should have 1,2")
	}
	if g.HasVertex(BasicEdge(2, 3)) {
		t.Fatal("should not have 2,3")
	}
}

func TestGraphEdgesFrom(t *testing.T) {
	var g Graph
	g.Add(1)
	g.Add(2)
	g.Add(3)
	g.Connect(BasicEdge(1, 3))
	g.Connect(BasicEdge(2, 3))

	edges := g.EdgesFrom(1)

	var expected Set
	expected.Add(BasicEdge(1, 3))

	var s Set
	for _, e := range edges {
		s.Add(e)
	}

	if s.Intersection(&expected).Len() != expected.Len() {
		t.Fatalf("bad: %#v", edges)
	}
}

func TestGraphEdgesTo(t *testing.T) {
	var g Graph
	g.Add(1)
	g.Add(2)
	g.Add(3)
	g.Connect(BasicEdge(1, 3))
	g.Connect(BasicEdge(1, 2))

	edges := g.EdgesTo(3)

	var expected Set
	expected.Add(BasicEdge(1, 3))

	var s Set
	for _, e := range edges {
		s.Add(e)
	}

	if s.Intersection(&expected).Len() != expected.Len() {
		t.Fatalf("bad: %#v", edges)
	}
}

type hashVertex struct {
	code interface{}
}

func (v *hashVertex) Hashcode() interface{} {
	return v.code
}

func (v *hashVertex) Name() string {
	return fmt.Sprintf("%#v", v.code)
}

const testGraphBasicStr = `
1
  3
2
3
`

const testGraphEmptyStr = `
1
2
3
`

const testGraphRemoveStr = `
1
2
`

const testGraphReplaceStr = `
1
  42
3
42
  3
`

const testGraphReplaceSelfStr = `
1
  2
2
  3
3
`
