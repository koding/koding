package index

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"

	"koding/klient/machine/index/node"
)

// Node represents a file tree.
//
// A single node represents a file or a directory.
//
// Nodes marked with node.EntryPromiseDel flag are marked
// as deleted, and are not going to be reachable via
// Lookup, Count methods. Deleting such nodes is a nop.
// This is how Node implements shallow delete.
type Node struct {
	Sub   map[string]*Node `json:"d"`
	Entry *node.Entry      `json:"e,omitempty"`
}

func newNode() *Node {
	return &Node{
		Sub:   make(map[string]*Node),
		Entry: node.NewEntry(0, 0755|os.ModeDir, node.RootInodeID),
	}
}

// Add adds the given entry under the given path.
//
// Any deleted node, encountered on the tree path that, is going to
// be undeleted (having the node.EntryPromiseDel flag removed).
func (nd *Node) Add(path string, entry *node.Entry) {
	if path == "/" || path == "" {
		nd.Entry = entry
		return
	}

	var node string

	for {
		if nd.Deleted() {
			nd.undelete()
		}

		node, path = split(path)

		sub, ok := nd.Sub[node]
		if !ok {
			sub = newNode()
			nd.Sub[node] = sub
		}

		if path == "" {
			sub.Entry = entry
			return
		}

		nd = sub
	}
}

// Del disconnected a whole subtree rooted at a node given by the path.
//
// Del will ignore and do not disconnect nodes which are marked as deleted.
func (nd *Node) Del(path string) {
	var node string

	for {
		if nd.Deleted() {
			return
		}

		node, path = split(path)
		if path == "" {
			delete(nd.Sub, node)
			return
		}

		sub, ok := nd.Sub[node]
		if !ok {
			return
		}

		nd = sub
	}
}

// Clone creates a deep copy of node.
func (nd *Node) Clone() *Node {
	cpy := &Node{
		Sub: make(map[string]*Node, len(nd.Sub)),
	}

	for sub, node := range nd.Sub {
		if node != nil {
			cpy.Sub[sub] = node.Clone()
		} else {
			cpy.Sub[sub] = nil
		}
	}

	if nd.Entry != nil {
		cpy.Entry = nd.Entry.Clone()
	}

	return cpy
}

// PromiseAdd adds a node under the given path marked as newly added.
//
// If the node already exists, it'd be only marked with node.EntryPromiseAdd flag.
//
// If the node is already marked as newly added, the method is a no-op.
//
// If entry.Mode is non-zero, the effective node's entry is overwritten
// with this value.
//
// Rest of entry's fields are currently ignored.
func (nd *Node) PromiseAdd(path string, entry *node.Entry) {
	var newE *node.Entry

	if nd, ok := nd.lookup(path, true); ok {
		newE = nd.Entry
		newE.MergeIn(entry)
	} else {
		newE = node.NewEntry(entry.File.Size, entry.File.Mode, 0)
		newE.MergeIn(entry)
	}

	newE.Virtual.Promise.Swap(node.EntryPromiseAdd, node.EntryPromiseDel)
	nd.Add(path, newE)
}

// PromiseDel marks a node under the given path as deleted.
//
// If the node does not exist or is already marked as deleted, then
// method is no-op.
//
// If node is non-nil, then it's used instead of looking it up
// by the given path.
func (nd *Node) PromiseDel(path string, n *Node) {
	if n == nil {
		var ok bool
		n, ok = nd.Lookup(path)
		if !ok {
			return
		}
	}

	n.Entry.Virtual.Promise.Swap(node.EntryPromiseDel, node.EntryPromiseAdd)
}

// Count counts nodes which Entry.Size is at most maxsize.
//
// If maxsize is 0, the method is a no-op.
// If maxsize is < 0, the method counts all nodes.
//
// Count ignores nodes marked as deleted and/or virtual.
func (nd *Node) Count(maxsize int64) int {
	return nd.count(maxsize, false)
}

// CountAll counts nodes which Entry.Size is at most maxsize.
//
// If maxsize is 0, the method is a no-op.
// If maxsize is < 0, the method counts all nodes.
//
// CountAll does not ignore nodes marked as deleted and/or virtual.
func (nd *Node) CountAll(maxsize int64) int {
	return nd.count(maxsize, true)
}

func (nd *Node) count(maxsize int64, all bool) (count int) {
	if maxsize == 0 {
		return 0 // no-op
	}

	cur, stack := (*Node)(nil), []*Node{nd}

	for len(stack) != 0 {
		cur, stack = stack[0], stack[1:]

		if !all && (cur.Deleted() || cur.Virtual()) {
			continue
		}

		if cur.Entry != nil && (maxsize < 0 || cur.Entry.File.Size <= maxsize) {
			count++
		}

		for _, nd := range cur.Sub {
			stack = append(stack, nd)
		}
	}

	return count
}

// DiskSize sums all Entry.Size of the nodes, given the condition the size
// is at most maxsize.
//
// If maxsize is 0, the method is a no-op.
// If maxsize is <0, all the nodes are summed up.
//
// DiskSize ignores nodes marked as deleted and/or virtual.
func (nd *Node) DiskSize(maxsize int64) (size int64) {
	return nd.diskSize(maxsize, false)
}

// DiskSizeAll sums all Entry.Size of the nodes, given the condition the size
// is at most maxsize.
//
// If maxsize is 0, the method is a no-op.
// If maxsize is <0, all the nodes are sumed up.
//
// DiskSizeAll does not ignore nodes marked as deleted and/or virtual.
func (nd *Node) DiskSizeAll(maxsize int64) (size int64) {
	return nd.diskSize(maxsize, true)
}

func (nd *Node) diskSize(maxsize int64, all bool) (size int64) {
	if maxsize == 0 {
		return 0 // no-op
	}

	stack := []*Node{nd}

	for len(stack) != 0 {
		nd, stack = stack[0], stack[1:]

		if !all && (nd.Deleted() || nd.Virtual()) {
			continue
		}

		if nd.Entry != nil && (maxsize < 0 || nd.Entry.File.Size <= maxsize) {
			size += nd.Entry.File.Size
		}

		for _, nd := range nd.Sub {
			stack = append(stack, nd)
		}
	}

	return size
}

// ForEach traverses the tree and calls fn on every node's entry.
//
// It ignored nodes marked as deleted.
func (nd *Node) ForEach(fn func(string, *node.Entry)) {
	nd.forEach(fn, false)
}

// ForEachAll traverses the tree and calls fn on every node's entry.
func (nd *Node) ForEachAll(fn func(string, *node.Entry)) {
	nd.forEach(fn, true)
}

func (nd *Node) forEach(fn func(string, *node.Entry), deleted bool) {
	type node struct {
		path string
		node *Node
	}

	n, stack := node{}, make([]node, 0, len(nd.Sub))

	// Add root node to stack.
	stack = append(stack, node{
		path: "",
		node: nd,
	})
	for len(stack) != 0 {
		n, stack = stack[0], stack[1:]

		if n.node.Deleted() && !deleted {
			continue
		}

		for path, nd := range n.node.Sub {
			stack = append(stack, node{
				path: filepath.Join(n.path, path),
				node: nd,
			})
		}

		fn(n.path, n.node.Entry)
	}
}

// Lookup looks up a node given by the path ignoring any of the node
// that is marked as deleted.
func (nd *Node) Lookup(path string) (*Node, bool) {
	return nd.lookup(path, false)
}

// LookupAll looks up a node given by the path.
func (nd *Node) LookupAll(path string) (*Node, bool) {
	return nd.lookup(path, true)
}

func (nd *Node) lookup(path string, deleted bool) (*Node, bool) {
	if path == "/" || path == "" {
		return nd.shallowCopy(), true
	}

	var node string

	for {
		if nd.Deleted() && !deleted {
			return nil, false
		}

		node, path = split(path)

		sub, ok := nd.Sub[node]
		if !ok {
			return nil, false
		}

		if path == "" {
			return sub.shallowCopy(), true
		}

		nd = sub
	}
}

// IsDir tells whether a node is a directory.
func (nd *Node) IsDir() bool {
	return nd.Entry.File.Mode.IsDir()
}

// Deleted tells whether node is marked as deleted.
func (nd *Node) Deleted() bool {
	return nd.Entry.Virtual.Promise.Deleted()
}

// Virtual tells whether node is marked as virtual.
func (nd *Node) Virtual() bool {
	return nd.Entry.Virtual.Promise&node.EntryPromiseVirtual != 0
}

func (nd *Node) undelete() {
	nd.Entry.Virtual.Promise.Swap(0, node.EntryPromiseDel)
}

func (nd *Node) shallowCopy() *Node {
	if nd.Sub != nil {
		sub := make(map[string]*Node, len(nd.Sub))

		for k, v := range nd.Sub {
			sub[k] = v
		}

		return &Node{
			Sub:   sub,
			Entry: nd.Entry,
		}
	}

	return nd
}

func split(path string) (string, string) {
	if path == "" {
		return "", ""
	}

	if path[0] == '/' {
		path = path[1:]
	}

	if i := strings.IndexRune(path, '/'); i != -1 {
		return path[:i], path[i+1:]
	}

	return path, ""
}

var _ json.Unmarshaler = (*Node)(nil)

// UnmarshalJSON satisfies json.Unmarshaler interface. It initializes empty sub
// map when it's omitted in serialized data.
//
// Note: this is a fixing function that was created due to `omitempty` tag
// in Node's sub field.
func (nd *Node) UnmarshalJSON(data []byte) error {
	type tmp Node

	tnd := tmp{}
	if err := json.Unmarshal(data, &tnd); err != nil {
		return err
	}

	if *nd = Node(tnd); nd.Sub == nil {
		nd.Sub = make(map[string]*Node)
	}

	return nil
}

// ToTree converts node to its equivalent node.Tree representation.
func (nd *Node) ToTree() *node.Tree {
	tree := node.NewTree()
	nd.ForEachAll(func(path string, entry *node.Entry) {
		tree.DoPath(path, node.Insert(entry))
	})

	tree.DoInode(node.RootInodeID, func(_ node.Guard, n *node.Node) {
		if n == nil {
			panic("root node cannot be nil")
		}
		n.UnsetPromises()
	})

	return tree
}
