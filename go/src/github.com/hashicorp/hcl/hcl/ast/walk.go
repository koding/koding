package ast

import "fmt"

// Walk traverses an AST in depth-first order: It starts by calling fn(node);
// node must not be nil.  If f returns true, Walk invokes f recursively for
// each of the non-nil children of node, followed by a call of f(nil).
func Walk(node Node, fn func(Node) bool) {
	if !fn(node) {
		return
	}

	switch n := node.(type) {
	case *File:
		Walk(n.Node, fn)
	case *ObjectList:
		for _, item := range n.Items {
			Walk(item, fn)
		}
	case *ObjectKey:
		// nothing to do
	case *ObjectItem:
		for _, k := range n.Keys {
			Walk(k, fn)
		}
		Walk(n.Val, fn)
	case *LiteralType:
		// nothing to do
	case *ListType:
		for _, l := range n.List {
			Walk(l, fn)
		}
	case *ObjectType:
		Walk(n.List, fn)
	default:
		fmt.Printf(" unknown type: %T\n", n)
	}

	fn(nil)
}

// Rewrite traverses an AST in depth-first order: It starts by calling
// fn(node); node must not be nil. If fn returns a non-nil node, Rewriter invokes
// fn recursively for each of the non-nil children of node, followed by a call
// of fn(nil). Rewrite can be used to rewrite the entire AST by returning the
// rewritten node of the function fn.
func Rewrite(node Node, fn func(Node) Node) (rewritten Node) {
	if rewritten = fn(node); rewritten == nil {
		return rewritten
	}

	switch n := node.(type) {
	case *File:
		n.Node = Rewrite(n.Node, fn)
	case *ObjectList:
		for i, item := range n.Items {
			n.Items[i] = Rewrite(item, fn).(*ObjectItem)
		}
	case *ObjectKey:
		// nothing to do
	case *ObjectItem:
		for i, k := range n.Keys {
			n.Keys[i] = Rewrite(k, fn).(*ObjectKey)
		}
		n.Val = Rewrite(n.Val, fn)
	case *LiteralType:
		// nothing to do
	case *ListType:
		for i, l := range n.List {
			n.List[i] = Rewrite(l, fn)
		}
	case *ObjectType:
		n.List = Rewrite(n.List, fn).(*ObjectList)
	default:
		fmt.Printf("unknown type: %T\n", n)
	}

	return rewritten
}
