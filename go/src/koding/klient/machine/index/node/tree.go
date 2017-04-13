package node

import (
	"encoding/json"
	"errors"
	"os"
	"path"
	"strings"
	"sync"
	"sync/atomic"
)

// RootInodeID is a Inode value set to all root nodes in tree.
const RootInodeID = 1

func defaultInodeIDGenerator() func() uint64 {
	var current uint64 = RootInodeID
	return func() uint64 {
		inodeID := atomic.AddUint64(&current, 1)
		if inodeID == RootInodeID {
			return atomic.AddUint64(&current, 1)
		}

		return inodeID
	}
}

var (
	_ json.Marshaler   = (*Tree)(nil)
	_ json.Unmarshaler = (*Tree)(nil)
)

// Tree is a wrapper on Nodes that allows safe manipulation of stored Nodes.
type Tree struct {
	// InodeGen is a function used to generate INodes for Tree entries. If nil,
	// the default one will be used.
	inGen func() uint64
	mu    sync.Mutex
	root  *Node
}

// NewTree creates a new Tree instance initialized with a single root node.
func NewTree() *Tree {
	return NewTreeInodeGen(defaultInodeIDGenerator())
}

// NewTreeInodeGen creates a new Tree instance initialized with a single root
// node. This function allows to specify custom inode ID generator.
func NewTreeInodeGen(inGen func() uint64) *Tree {
	t := &Tree{
		inGen: inGen,
		root:  NewNode(""),
	}

	t.root.Entry.Virtual.Inode = RootInodeID

	return t
}

// Clone returns a deep copy of called tree.
func (t *Tree) Clone() *Tree {
	return &Tree{
		inGen: t.inGen,
		root:  t.root.Clone(),
	}
}

// DoPath safely calls a given predicate on node pointed by nodePath argument.
func (t *Tree) DoPath(nodePath string, pred Predicate) {
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
			t.addChild(live, ci, c)
		}
	} else {
		// User wants to remove the node so, if it's a live branch we need to
		// remove it from its parent. In this case live == subj.
		if c == nil {
			t.rmChild(p, pi, live)
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

	if err := json.Unmarshal(data, &t.root); err != nil {
		return err
	}

	t.inGen = defaultInodeIDGenerator()
	if t.root == nil {
		t.root = NewNode("")
	}

	if t.root.Entry == nil {
		return errors.New("tree: root entry is nil")
	}

	// Set initial Inodes.
	t.reset()

	return nil
}

func (t *Tree) reset() {
	t.root.Walk(func(parent, n *Node) {
		if parent == nil {
			n.Entry.Virtual.Inode = RootInodeID
		} else {
			n.Entry.Virtual.Inode = t.inGen()
		}

		n.Entry.Virtual.Promise, n.Entry.Virtual.RefCount = 0, 0
	})
}

func (t *Tree) find(names []string) (pi int, p, live *Node, ci int, c, subj *Node) {
	live, subj = t.root, t.root // Start from the root node.
	for i := range names {
		idx := SearchNodes(subj.children, names[i])
		// Value with a given name is not present in current node.
		if idx >= len(subj.children) || subj.children[idx].Name != names[i] {
			e := &Entry{}
			if i < len(names)-1 {
				e.File.Mode = (subj.Entry.File.Mode & os.ModePerm) | os.ModeDir
			}

			n := NewNodeEntry(names[i], e)
			if c == nil {
				// First new node.
				ci, c = idx, n
			} else if len(c.children) == 0 {
				// First branch in shadowed node.
				c.children = append(c.children, n)
			} else if len(c.children) == 1 {
				// Another shadowed sub-branch, move forward till empty one.
				child := c.children[0]
				for len(child.children) > 0 {
					child = child.children[0]
				}
				child.children = append(child.children, n)
			} else {
				panic("logic error: invalid number of shadowed children")
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

func (t *Tree) addChild(n *Node, pos int, child *Node) {
	if child == nil {
		panic("cannot add nil node to the tree")
	}

	if old := n.addChild(pos, child); old != nil {
		// TODO: Garbage collect.
	}

	if child.Entry.Virtual.Inode == 0 {
		child.Entry.Virtual.Inode = t.inGen()
	}

	// Ensure that child branches are set.
	child.Walk(func(parent, child *Node) {
		if parent == nil {
			child.parent = n
		} else {
			child.parent = parent
		}

		if child.Entry.Virtual.Inode == 0 {
			child.Entry.Virtual.Inode = t.inGen()
		}
	})
}

func (t *Tree) rmChild(n *Node, pos int, child *Node) {
	n.rmChild(pos, child)

	if child != nil {
		// TODO Garbage collect.
	}
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

			stack = append(stack[1:], stack[0].children...)
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

		for i := range n.children {
			childPath := path.Join(nodePath, n.children[i].Name)
			// Save some function calls for regural files.
			if len(n.children[i].children) == 0 {
				f(childPath, n.children[i])
			} else {
				subFn(childPath, n.children[i])
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
