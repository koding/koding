package node

import (
	"os"
	"sort"
	"strings"
	"sync"
)

// Node
type Node struct {
	name     string  // name.
	entry    *Entry  // entry.
	children []*Node // children.
}

// NewNode
func NewNode(name string) *Node {
	return &Node{
		name:     name,
		entry:    NewEntry(0, 0755|os.ModeDir),
		children: make([]*Node, 0),
	}
}

// NewNodeEntry
func NewNodeEntry(name string, entry *Entry) *Node {
	return &Node{
		name:     name,
		entry:    entry,
		children: make([]*Node, 0),
	}
}

// Name returns node name.
func (n *Node) Name() string { return n.name }

// Entry returns node entry data.
func (n *Node) Entry() *Entry { return n.entry }

// NodeSlice attaches the methods of sortInterface to []*Node, sorting in
// asceding order.
type NodeSlice []*Node

func (ns NodeSlice) Len() int           { return len(ns) }
func (ns NodeSlice) Less(i, j int) bool { return ns[i].name < ns[j].name }
func (ns NodeSlice) Swap(i, j int)      { ns[i], ns[j] = ns[j], ns[i] }

// SearchNodes searches for name in a sorted slice of nodes and returns the
// index as specified by sort.Search. The return value is the index to insert
// new node if node with provided name is not present. The slice must be sorted
// in ascending order.
func SearchNodes(ns []*Node, name string) int {
	return sort.Search(len(ns), func(i int) bool { return ns[i].name >= name })
}

type Predicate func(*Node) bool

func Insert(entry *Entry) Predicate {
	return func(n *Node) bool {
		n.entry = entry
		return true
	}
}

func Delete() Predicate {
	return func(_ *Node) bool {
		return false
	}
}

// Tree todo
type Tree struct {
	mu   sync.Mutex
	root *Node
}

// NewTree todo
func NewTree() *Tree {
	return &Tree{
		root: NewNode(""),
	}
}

func (t *Tree) Do(path string, pred Predicate) {
	names := split(path)
	if len(names) == 0 {
		t.mu.Lock()
		// Root branch is neither a shadow branch nor can be deleted so, we can
		// only call predicate on it.
		pred(t.root)
		t.mu.Unlock()
		return
	}

	t.mu.Lock()

	// Find node in a tree or create a shadow branch not attached to anything.
	pi, p, live, ci, c, subj := t.find(names)

	// subj stores requested node.
	if ok := pred(subj); ok {
		// User wants to keep the node so, if it's a shadow branch we need to
		// attach it to the last `live` branch.
		if c != nil {
			// Child for live branch is present.
			addChild(live, ci, c)
		}
	} else {
		// User wants to remove the node so, if it's a live branch we need to
		// remove it from its parent. In this case live == subj.
		if c == nil {
			rmChild(p, pi, live)
		}
	}
}

func (t *Tree) find(names []string) (pi int, p, live *Node, ci int, c, subj *Node) {
	live, subj = t.root, t.root // Start from the root node.
	for i := range names {
		idx := SearchNodes(subj.children, names[i])
		// Value with a given name is not present in current node.
		if idx >= len(subj.children) || subj.children[idx].name != names[i] {
			e := &Entry{}
			if i < len(names)-1 {
				// This entry is a part of larger path so make it a directory.
				e.SetMode((subj.entry.Mode() & os.ModePerm) | os.ModeDir)
			}

			n := NewNodeEntry(names[i], e)
			if c == nil {
				// First new node.
				ci, c = idx, n
			} else {
				// Another branch in new Node.
				c.children = append(c.children, n)
			}

			subj = n
		} else {
			pi, p = idx, subj
			subj = subj.children[idx]
			live = subj
		}
	}

	return
}

func addChild(n *Node, pos int, child *Node) {
	if pos >= len(n.children) {
		// Put at the end of children slice.
		n.children = append(n.children, child)
		return
	}

	if n.children[pos].name == child.name {
		// Replace if the children already exist. This is logically impossible
		// however do this for the sake of correctness.
		n.children[pos] = child
		return
	}

	// Put child between others preserving lexicographical order.
	n.children = append(n.children, nil)
	copy(n.children[pos+1:], n.children[pos:])
	n.children[pos] = child
}

func rmChild(n *Node, pos int, child *Node) {
	if pos >= len(n.children) {
		// Cannot remove from position larger than number of elements in slice.
		return
	}

	if n.children[pos].name != child.name {
		// If node names are not equal we do nothing. As in case of add, this
		// is not possible on correctly synchronized logic but added for the
		// sake of correctness.
		return
	}

	copy(n.children[pos:], n.children[pos+1:])
	n.children[len(n.children)-1] = nil // let GC decrease refcounter.
	n.children = n.children[:len(n.children)-1]
}

func split(path string) []string {
	names := strings.Split(path, "/")

	// Delete empty or "." sub-paths.
	for i := 0; i < len(names); i++ {
		if names[i] == "" || names[i] == "." {
			names = append(names[:i], names[i+1:]...)
			i--
		}
	}

	return names
}
