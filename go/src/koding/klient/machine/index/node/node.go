package node

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"sort"
)

var (
	_ json.Marshaler   = (*Node)(nil)
	_ json.Unmarshaler = (*Node)(nil)
)

// Node stores a single tree entity. All method calls performed on Node must
// be synchronized.
type Node struct {
	Name  string
	Entry *Entry

	children []*Node
	parent   *Node
}

// NewNode creates a new node with zero-size entry and directory mode.
func NewNode(name string, inode uint64) *Node {
	return &Node{
		Name:     name,
		Entry:    NewEntry(0, 0755|os.ModeDir, inode),
		children: make([]*Node, 0),
		parent:   nil,
	}
}

// NewNodeEntry creates a new node with provided entry.
func NewNodeEntry(name string, entry *Entry) *Node {
	return &Node{
		Name:     name,
		Entry:    entry,
		children: nil,
		parent:   nil,
	}
}

// IsShadowed returns true when node is not present in tree.
func (n *Node) IsShadowed() bool { return n.Entry == nil || *n.Entry == emptyEntry }

// Exist returns true for nodes that are considered as existing files. This
// method can be called on nil nodes.
func (n *Node) Exist() bool {
	return n != nil && n.Entry.Virtual.Promise.Exist()
}

// Clone returns a deep copy of called node.
func (n *Node) Clone() *Node {
	c := &Node{
		Name:     n.Name,
		children: make([]*Node, 0, len(n.children)),
	}

	if n.Entry != nil {
		c.Entry = n.Entry.Clone()
	}

	for i := range n.children {
		c.children = append(c.children, n.children[i].Clone())
	}

	for i := range c.children {
		c.children[i].parent = c
	}

	return c
}

// Parent returns node parent or nil.
func (n *Node) Parent() *Node {
	return n.parent
}

// Orphan checks if node parent exist.
func (n *Node) Orphan() bool {
	return n.parent == nil
}

// Path uses node parents to create a full path. It starts from root node.
func (n *Node) Path() string {
	var (
		root = n
		toks = []string{n.Name}
	)

	// Go till root node.
	for root.parent != nil {
		root = root.parent
		toks = append(toks, root.Name)
	}

	// Reverse the slice.
	for l, r := 0, len(toks)-1; l < r; l, r = l+1, r-1 {
		toks[l], toks[r] = toks[r], toks[l]
	}

	return filepath.Join(toks...)
}

// ChildN returns the number of stored children.
func (n *Node) ChildN() int {
	return len(n.children)
}

// AddChild adds new child to the node. If child node is invalid, this method
// panics.
func (n *Node) AddChild(child *Node) {
	if child == nil {
		panic("cannot add nil node to the tree")
	}

	pos, _ := n.getChild(child.Name)
	n.addChild(pos, child)

	child.Walk(func(parent, child *Node) {
		if parent == nil {
			child.parent = n
		} else {
			child.parent = parent
		}
	})
}

func (n *Node) addChild(pos int, child *Node) (old *Node) {
	if child.Entry == nil {
		panic("node" + n.Name + " cannot contain nil entry: ")
	}

	if pos >= len(n.children) {
		// Put at the end of children slice.
		n.children = append(n.children, child)
		return
	}

	if n.children[pos].Name == child.Name {
		// Replace if the children already exist.
		old = n.children[pos]
		old.parent = nil
		n.children[pos] = child
		return
	}

	// Put child between others preserving lexicographical order.
	n.children = append(n.children, nil)
	copy(n.children[pos+1:], n.children[pos:])
	n.children[pos] = child

	return
}

// RmChild removes child and all its children from node.
func (n *Node) RmChild(name string) {
	n.rmChild(n.getChild(name))
}

func (n *Node) rmChild(pos int, child *Node) {
	if child == nil {
		// Child was not found, so there is nothing to remove.
		return
	}

	copy(n.children[pos:], n.children[pos+1:])
	n.children[len(n.children)-1] = nil // let GC decrease refcounter.
	n.children = n.children[:len(n.children)-1]

	child.parent = nil
}

// GetChild gets child node with a given name from called Node. If return value
// is nil, the child was not found.
func (n *Node) GetChild(name string) (child *Node) {
	_, child = n.getChild(name)
	return
}

func (n *Node) getChild(name string) (int, *Node) {
	pos := SearchNodes(n.children, name)
	if pos >= len(n.children) || n.children[pos].Name != name {
		return pos, nil
	}

	return pos, n.children[pos]
}

// Children iterates over node children starting from provided offset.
func (n *Node) Children(offset int, fn func(*Node)) {
	if offset < len(n.children) {
		for _, child := range n.children[offset:] {
			fn(child)
		}
	}
}

// Walk recursively walks the node and all its children.
func (n *Node) Walk(walkFn func(*Node, *Node)) {
	walkFn(nil, n)
	n.walk(walkFn)
}

// Walk recursively walks the node and all its children.
func (n *Node) walk(walkFn func(*Node, *Node)) {
	for i := range n.children {
		walkFn(n, n.children[i])
		n.children[i].walk(walkFn)
	}
}

const notPresent = EntryPromiseVirtual | EntryPromiseDel

// PromiseVirtual sets node as virtual.
func (n *Node) PromiseVirtual() {
	n.setPromiseRec(EntryPromiseVirtual)
}

// PromiseAdd sets node path as added. Root path virtual entry is not set.
func (n *Node) PromiseAdd() {
	var root = n
	for root.parent != nil {
		if root.Entry.Virtual.Promise&notPresent != 0 {
			root.Entry.Virtual.Promise.Swap(EntryPromiseAdd, notPresent)
		}
		root = root.parent
	}
}

// PromiseUpdate sets node as updated. Root node is not set.
func (n *Node) PromiseUpdate() {
	if n.parent != nil {
		n.Entry.Virtual.Promise = EntryPromiseUpdate
	}
}

// PromiseDel sets node as deleted.
func (n *Node) PromiseDel() {
	n.setPromiseRec(EntryPromiseDel)
}

func (n *Node) setPromiseRec(ep EntryPromise) {
	if n.Entry.Virtual.Promise == ep {
		return
	}

	n.Entry.Virtual.Promise = ep
	for i := range n.children {
		n.children[i].setPromiseRec(ep)
	}
}

// UnsetPromises removes all promises from a given node and all its parents.
func (n *Node) UnsetPromises() {
	var root = n
	for root.parent != nil {
		root.Entry.Virtual.Promise = 0
		root = root.parent
	}
}

// MarshalJSON satisfies json.Marshaler interface. It safely marshals Node
// private data to JSON format.
func (n *Node) MarshalJSON() ([]byte, error) {
	node := struct {
		Name     string  `json:"name"`
		Entry    *Entry  `json:"entry,omitempty"`
		Children []*Node `json:"children,omitempty"`
	}{
		Name:     n.Name,
		Entry:    n.Entry,
		Children: n.children,
	}

	return json.Marshal(node)
}

// UnmarshalJSON satisfies json.Unmarshaler interface. It is used to unmarshal
// data into private Node fields.
func (n *Node) UnmarshalJSON(data []byte) (err error) {
	node := struct {
		Name     string  `json:"name"`
		Entry    *Entry  `json:"entry,omitempty"`
		Children []*Node `json:"children,omitempty"`
	}{}

	if err = json.Unmarshal(data, &node); err != nil {
		return err
	}

	n.Name, n.Entry, n.children = node.Name, node.Entry, node.Children

	// Initialize node parents.
	n.Walk(func(parent, node *Node) {
		if node == nil && err == nil {
			err = errors.New("node: invalid node format")
		}

		if err != nil {
			return
		}

		node.parent = parent
	})

	return err
}

// MvChild moves source node child to destination node. The child name will be
// replaced in destination node to destination name. This function returns
// replaced node if present and if the move was successful.
func MvChild(nSrc *Node, nameSrc string, nDst *Node, nameDst string) (replaced *Node, ok bool) {
	if nSrc == nil {
		panic("source node is nil")
	}
	if nDst == nil {
		panic("destination node is nil")
	}

	posChildSrc, nChildSrc := nSrc.getChild(nameSrc)
	if nChildSrc == nil {
		// There is no source node, so nothing to move.
		return nil, false
	}

	// Remove child from the source.
	nSrc.rmChild(posChildSrc, nChildSrc)

	// Change moved node name.
	nChildSrc.Name = nameDst

	// Get source name position in destination and replace destination node.
	posChildDst, _ := nDst.getChild(nameDst)
	replaced = nDst.addChild(posChildDst, nChildSrc)

	// Change moved node parent to destination one.
	nChildSrc.parent = nDst

	return replaced, true
}

// NodeSlice attaches the methods of sortInterface to []*Node, sorting in
// asceding order.
type NodeSlice []*Node

func (ns NodeSlice) Len() int           { return len(ns) }
func (ns NodeSlice) Less(i, j int) bool { return ns[i].Name < ns[j].Name }
func (ns NodeSlice) Swap(i, j int)      { ns[i], ns[j] = ns[j], ns[i] }

// SearchNodes searches for name in a sorted slice of nodes and returns the
// index as specified by sort.Search. The return value is the index to insert
// new node if node with provided name is not present. The slice must be sorted
// in ascending order.
func SearchNodes(ns []*Node, name string) int {
	return sort.Search(len(ns), func(i int) bool { return ns[i].Name >= name })
}
