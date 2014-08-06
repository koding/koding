package goquery

import (
	"testing"
)

func TestAdd(t *testing.T) {
	sel := Doc().Find("div.row-fluid").Add("a")
	AssertLength(t, sel.Nodes, 19)
}

func TestAddRollback(t *testing.T) {
	sel := Doc().Find(".pvk-content")
	sel2 := sel.Add("a").End()
	AssertEqual(t, sel, sel2)
}

func TestAddSelection(t *testing.T) {
	sel := Doc().Find("div.row-fluid")
	sel2 := Doc().Find("a")
	sel = sel.AddSelection(sel2)
	AssertLength(t, sel.Nodes, 19)
}

func TestAddSelectionNil(t *testing.T) {
	sel := Doc().Find("div.row-fluid")
	AssertLength(t, sel.Nodes, 9)

	sel = sel.AddSelection(nil)
	AssertLength(t, sel.Nodes, 9)
}

func TestAddSelectionRollback(t *testing.T) {
	sel := Doc().Find(".pvk-content")
	sel2 := sel.Find("a")
	sel2 = sel.AddSelection(sel2).End()
	AssertEqual(t, sel, sel2)
}

func TestAddNodes(t *testing.T) {
	sel := Doc().Find("div.pvk-gutter")
	sel2 := Doc().Find(".pvk-content")
	sel = sel.AddNodes(sel2.Nodes...)
	AssertLength(t, sel.Nodes, 9)
}

func TestAddNodesNone(t *testing.T) {
	sel := Doc().Find("div.pvk-gutter").AddNodes()
	AssertLength(t, sel.Nodes, 6)
}

func TestAddNodesRollback(t *testing.T) {
	sel := Doc().Find(".pvk-content")
	sel2 := sel.Find("a")
	sel2 = sel.AddNodes(sel2.Nodes...).End()
	AssertEqual(t, sel, sel2)
}

func TestAndSelf(t *testing.T) {
	sel := Doc().Find(".span12").Last().AndSelf()
	AssertLength(t, sel.Nodes, 2)
}

func TestAndSelfRollback(t *testing.T) {
	sel := Doc().Find(".pvk-content")
	sel2 := sel.Find("a").AndSelf().End().End()
	AssertEqual(t, sel, sel2)
}
