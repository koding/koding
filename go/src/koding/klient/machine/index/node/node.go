package node

import (
	"errors"
	"path/filepath"
)

// ErrNotFound is returned when provided node was not found during lookup.
var ErrNotFound = errors.New("node not found")

// Noder is an interface that must be implemented by entity that represents a
// single file or directory inside directory tree.
type Noder interface {
	Name() string  // Name of the node/file/directory.
	Entry() *Entry // Entry, accessing this structure is TS.
	//Children(func(Noder)) // Node sub-nodes, always sorted.
	//Clone Noder // Clones the node.
}

// Tree represents growable or shrinkable Noder tree.
type Tree interface {
	Add(path string, e *Entry)         // Adds new Entry under a given path.
	Lookup(path string) (Noder, error) // Shearches for nodes under a given path.
	Delete(path string)                // Removes the node under a given path.
}

// WalkFunc represents a function that can be called on each entry visited by
// Walk function.
type WalkFunc func(path string, entry *Entry)

// Walk walks the node tree calling walkFn for each node stored by it. This
// function assumes no cycles inside provided noder.
func Walk(n Noder, walkFn WalkFunc) {
	walk("", n, walkFn)
}

func walk(root string, n Noder, walkFn WalkFunc) {
	if n == nil {
		return
	}

	path := filepath.Join(root, n.Name())

	// Call fn for noder itself.
	walkFn(path, n.Entry())

	// // Visit node children.
	// for _, child := range n.Children() {
	// 	walk(path, child, walkFn)
	// }
}

// Node
type Node struct {
	name     string
	entry    *Entry
	children []*Node
}

func NewNode() *Node {
	return nil
}

// Name
func (n *Node) Name() string {
	return n.name
}

// Entry
func (n *Node) Entry() *Entry {
	return n.entry
}

// Children
func (n *Node) Children(f func(ndr Noder)) {

}

// Add
func (n *Node) Add() {}
