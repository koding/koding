package node

import (
	"encoding/json"
	"os"
	"path"
	"sort"
	"strings"
	"sync"
)

// Node stores a single tree entity. All method calls performed on Node must
// be synchronized.
type Node struct {
	Name     string  `json:"name"`
	Entry    *Entry  `json:"entry,omitempty"`
	Children []*Node `json:"children,omitempty"`
}

// NewNode creates a new node with zero-size entry and directory mode.
func NewNode(name string) *Node {
	return &Node{
		Name:     name,
		Entry:    NewEntry(0, 0755|os.ModeDir),
		Children: make([]*Node, 0),
	}
}

// NewNodeEntry creates a new node with provided entry.
func NewNodeEntry(name string, entry *Entry) *Node {
	return &Node{
		Name:  name,
		Entry: entry,
	}
}

// IsShadowed returns true when node is not present in tree.
func (n *Node) IsShadowed() bool { return n.Entry == nil }

// Clone returns a deep copy of called node.
func (n *Node) Clone() *Node {
	c := &Node{
		Name: n.Name,
	}

	if n.Entry != nil {
		c.Entry = n.Entry.Clone()
	}

	for i := range n.Children {
		c.Children = append(c.Children, n.Children[i].Clone())
	}

	return c
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

// Predicate defines the read or write operation on the node. Node passed
// as argument can be safely modified. Any predicate function must return true
// in order to commit the changes.
type Predicate func(*Node) bool

// Insert adds or replaces a node pointed by provided nodePath. If the node nodePath
// doesn't exist it is created and nodes between inherit file permissions from
// the first present node in the tree.
func Insert(entry *Entry) Predicate {
	return func(n *Node) bool {
		n.Entry = entry
		return true
	}
}

// Delete removes the node and all its children from the tree.
func Delete() Predicate {
	return func(_ *Node) bool {
		return false
	}
}

// Walk calls provided function on root note and all its children.
func Walk(f func(*Node)) Predicate {
	return func(n *Node) bool {
		for stack := []*Node{n}; len(stack) != 0; {
			f(stack[0])

			stack = append(stack[1:], stack[0].Children...)
		}

		return true
	}
}

// WalkPath behaves like Walk but also sends path to the node.
func WalkPath(f func(string, *Node)) Predicate {
	var subFn func(string, *Node)

	subFn = func(nodePath string, n *Node) {
		// Call on root node.
		f(nodePath, n)

		for i := range n.Children {
			childPath := path.Join(nodePath, n.Children[i].Name)
			// Save some function calls for regural files.
			if len(n.Children[i].Children) == 0 {
				f(childPath, n.Children[i])
			} else {
				subFn(childPath, n.Children[i])
			}
		}
	}

	return func(n *Node) bool {
		subFn("", n)
		return true
	}
}

// Count stores the number of nodes in provided argument.
func Count(n *int) Predicate {
	return Walk(func(*Node) { (*n)++ })
}

// DiskSize stores the size of nodes in provided argument.
func DiskSize(size *int64) Predicate {
	return Walk(func(n *Node) {
		if n.Entry != nil {
			*size += n.Entry.File.Size
		}
	})
}

var (
	_ json.Marshaler   = (*Tree)(nil)
	_ json.Unmarshaler = (*Tree)(nil)
)

// Tree is a wrapper on Nodes that allows safe manipulation of stored Nodes.
type Tree struct {
	mu   sync.Mutex
	root *Node
}

// NewTree creates a new Tree instance initialized with a single root node.
func NewTree() *Tree {
	return &Tree{
		root: NewNode(""),
	}
}

// Clone returns a deep copy of called tree.
func (t *Tree) Clone() *Tree {
	return &Tree{
		root: t.root.Clone(),
	}
}

// Do safely calls a given predicate on node pointed by nodePath argument.
func (t *Tree) Do(nodePath string, pred Predicate) {
	names := split(nodePath)
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

	t.mu.Unlock()
}

// MarshalJSON satisfies json.Marshaler interface. It safely marshals Tree
// private data to JSON format.
func (t *Tree) MarshalJSON() ([]byte, error) {
	t.mu.Lock()
	defer t.mu.Unlock()

	return json.Marshal(t.root)
}

// UnmarshalJSON satisfies json.Unmarshaler interface. It is used to unmarshal
// data into private Tree fields.
func (t *Tree) UnmarshalJSON(data []byte) error {
	t.mu.Lock()
	defer t.mu.Unlock()

	return json.Unmarshal(data, &t.root)
}

func (t *Tree) find(names []string) (pi int, p, live *Node, ci int, c, subj *Node) {
	live, subj = t.root, t.root // Start from the root node.
	for i := range names {
		idx := SearchNodes(subj.Children, names[i])
		// Value with a given name is not present in current node.
		if idx >= len(subj.Children) || subj.Children[idx].Name != names[i] {
			e := &Entry{}
			if i < len(names)-1 {
				e.File.Mode = (subj.Entry.File.Mode & os.ModePerm) | os.ModeDir
			}

			n := NewNodeEntry(names[i], e)
			if c == nil {
				// First new node.
				ci, c = idx, n
			} else if len(c.Children) == 0 {
				// First branch in shadowed node.
				c.Children = append(c.Children, n)
			} else if len(c.Children) == 1 {
				// Another shadowed sub-branch, move forward till empty one.
				child := c.Children[0]
				for len(child.Children) > 0 {
					child = child.Children[0]
				}
				child.Children = append(child.Children, n)
			} else {
				panic("logic error: invalid number of shadowed children")
			}

			subj = n
		} else {
			pi, p = idx, subj
			subj = subj.Children[idx]
			live = subj
		}
	}

	return
}

func addChild(n *Node, pos int, child *Node) {
	if pos >= len(n.Children) {
		// Put at the end of children slice.
		n.Children = append(n.Children, child)
		return
	}

	if n.Children[pos].Name == child.Name {
		// Replace if the children already exist. This is logically impossible
		// however do this for the sake of correctness.
		n.Children[pos] = child
		return
	}

	// Put child between others preserving lexicographical order.
	n.Children = append(n.Children, nil)
	copy(n.Children[pos+1:], n.Children[pos:])
	n.Children[pos] = child
}

func rmChild(n *Node, pos int, child *Node) {
	if pos >= len(n.Children) {
		// Cannot remove from position larger than number of elements in slice.
		return
	}

	if n.Children[pos].Name != child.Name {
		// If node names are not equal we do nothing. As in case of add, this
		// is not possible on correctly synchronized logic but added for the
		// sake of correctness.
		return
	}

	copy(n.Children[pos:], n.Children[pos+1:])
	n.Children[len(n.Children)-1] = nil // let GC decrease refcounter.
	n.Children = n.Children[:len(n.Children)-1]
}

func split(nodePath string) []string {
	names := strings.Split(nodePath, "/")

	// Delete empty or "." sub-paths.
	for i := 0; i < len(names); i++ {
		if names[i] == "" || names[i] == "." {
			names = append(names[:i], names[i+1:]...)
			i--
		}
	}

	return names
}
