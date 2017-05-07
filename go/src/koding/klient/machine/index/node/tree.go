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
		for inodeID <= RootInodeID {
			inodeID = atomic.AddUint64(&current, 1)
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
	mu    sync.RWMutex
	root  *Node

	guard  Guard
	inodes map[uint64]*Node
}

// NewTree creates a new Tree instance initialized with a single root node.
func NewTree() *Tree {
	return NewTreeInodeGen(defaultInodeIDGenerator())
}

// NewTreeInodeGen creates a new Tree instance initialized with a single root
// node. This function allows to specify custom inode ID generator.
func NewTreeInodeGen(inGen func() uint64) *Tree {
	t := &Tree{
		inGen:  inGen,
		root:   NewNode("", RootInodeID),
		inodes: nil, // set by reset method.
	}

	t.guard = Guard{t: t}

	// Set initial Inodes.
	t.reset()

	return t
}

// GenerateInode uses tree generator to generate new node value.
func (t *Tree) GenerateInode() uint64 {
	return t.inGen()
}

// DataClone returns a deep copy of called tree without virtual parts and inode
// logic.
func (t *Tree) DataClone() *Tree {
	dc := &Tree{
		inGen:  t.inGen,
		root:   t.root.Clone(),
		inodes: make(map[uint64]*Node),
	}

	dc.guard = Guard{t: dc}

	return dc
}

// DoInode safely searches for a note that contains given inode. If not found,
// fn is called with nil node. All mutating operations on given node should
// be guarded by guard argument.
func (t *Tree) DoInode(inode uint64, fn func(Guard, *Node)) {
	t.mu.Lock()
	fn(t.guard, t.inodes[inode])
	t.mu.Unlock()
}

// DoInodeR behaves like DoInode but the provided function can not modify node
// argument in any way.
func (t *Tree) DoInodeR(inode uint64, fn func(*Node)) {
	t.mu.RLock()
	fn(t.inodes[inode])
	t.mu.RUnlock()
}

// DoInode2 behaves like DoInode but for two inodes.
func (t *Tree) DoInode2(inode1, inode2 uint64, fn func(Guard, *Node, *Node)) {
	t.mu.Lock()
	fn(t.guard, t.inodes[inode1], t.inodes[inode2])
	t.mu.Unlock()
}

// DoPath safely calls a given predicate on node pointed by nodePath argument.
func (t *Tree) DoPath(nodePath string, pred Predicate) {
	names := split(nodePath)
	if len(names) == 0 {
		t.mu.Lock()
		// Root branch is neither a shadow branch nor can be deleted so, we can
		// only call predicate on it.
		pred(t.guard, t.root)
		t.mu.Unlock()
		return
	}

	t.mu.Lock()

	// Find node in a tree or create a shadow branch not attached to anything.
	pi, p, live, ci, c, subj := t.find(names)

	// subj stores requested node.
	if ok := pred(t.guard, subj); ok {
		// User wants to keep the node so, if it's a shadow branch we need to
		// attach it to the last `live` branch.
		if c != nil {
			// Child for live branch is present.
			t.addChild(live, ci, c)
			subj.PromiseAdd()
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

// ExistCount returns the number of nodes that are proven to exist.
func (t *Tree) ExistCount() (count int) {
	t.DoPath("", ExistCount(&count))
	return
}

// ExistDiskSize returns the size of nodes that are proven to exist.
func (t *Tree) ExistDiskSize() (size int64) {
	t.DoPath("", ExistDiskSize(&size))
	return
}

// Count returns the total number of nodes to provided argument.
func (t *Tree) Count() (count int) {
	t.DoPath("", Count(&count))
	return
}

// DiskSize returns the total size of nodes to provided argument.
func (t *Tree) DiskSize() (size int64) {
	t.DoPath("", DiskSize(&size))
	return
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
		t.root = NewNode("", RootInodeID)
	}

	if t.root.Entry == nil {
		return errors.New("tree: root entry is nil")
	}

	t.guard = Guard{t: t}

	// Set initial Inodes.
	t.reset()

	return nil
}

func (t *Tree) reset() {
	t.inodes = make(map[uint64]*Node)
	t.root.Walk(func(parent, n *Node) {
		if parent == nil {
			n.Entry.File.Inode = RootInodeID
		}

		if n.Entry.File.Inode == 0 {
			n.Entry.File.Inode = t.inGen()
		}

		for {
			if _, ok := t.inodes[n.Entry.File.Inode]; !ok {
				break
			}
			n.Entry.File.Inode = t.inGen()
		}
		t.inodes[n.Entry.File.Inode] = n

		n.Entry.Virtual.Promise, n.Entry.Virtual.count = 0, 0
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
	if old := n.addChild(pos, child); old != nil {
		// Clean inodes map in order to not leak resources.
		old.Walk(func(_, n *Node) {
			delete(t.inodes, n.Entry.File.Inode)
		})
	}

	// Ensure that child branches are set.
	child.Walk(func(parent, child *Node) {
		if parent == nil {
			child.parent = n
		} else {
			child.parent = parent
		}

		if child.Entry.File.Inode == 0 {
			child.Entry.File.Inode = t.inGen()
		}

		for {
			if _, ok := t.inodes[child.Entry.File.Inode]; !ok {
				t.inodes[child.Entry.File.Inode] = child
				return
			}

			child.Entry.File.Inode = t.inGen()
		}
	})
}

func (t *Tree) changeInode(n *Node, inode uint64) uint64 {
	// Special case for root inode.
	old := n.Entry.File.Inode
	if old == RootInodeID {
		if inode != old {
			panic("root inode cannot be replaced: " + n.Path())
		}

		return inode
	}

	// Inode is already set.
	if old == inode {
		t.inodes[inode] = n
		return inode
	}

	// If provided inode is already taken, we can set it twice so find first
	// not taken one.
	for {
		if _, ok := t.inodes[inode]; !ok && inode >= RootInodeID {
			break
		}
		inode = t.inGen()
	}

	// This inode doesn't have valid inode so it should not be in tree.
	if _, ok := t.inodes[old]; old == 0 && ok {
		panic("zero node present in tree" + n.Path())
	} else if ok {
		delete(t.inodes, old)
	}

	n.Entry.File.Inode = inode
	t.inodes[inode] = n

	return inode
}

func (t *Tree) rmChild(n *Node, pos int, child *Node) {
	n.rmChild(pos, child)

	if child != nil {
		// Clean inodes map in order to not leak resources.
		child.Walk(func(_, n *Node) {
			delete(t.inodes, n.Entry.File.Inode)
		})
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

// Guard is used by tree to guard modification on nodes obtained after calling
// Tree's DoInode* mothods. It should not be used outside of these calls.
type Guard struct {
	t *Tree
}

// AddChild should be used instead n.AddChild inside DoInode callbacks.
func (g Guard) AddChild(n, child *Node) {
	if child == nil {
		panic("cannot add nil node to the tree")
	}

	pos, _ := n.getChild(child.Name)
	g.t.addChild(n, pos, child)
	child.PromiseAdd()
}

// RmChild should be used instead n.RmChild inside DoInode callbacks.
func (g Guard) RmChild(n *Node, name string) {
	pos, child := n.getChild(name)
	g.t.rmChild(n, pos, child)
}

// Repudiate makes child with given name an orphan.
func (g Guard) Repudiate(n *Node, name string) {
	n.RmChild(name)
}

// RmOrphan removes orphan nodes.
func (g Guard) RmOrphan(orphan *Node) {
	orphan.Walk(func(_, n *Node) {
		delete(g.t.inodes, n.Entry.File.Inode)
	})
}

// ChangeInode replaces inode value inside provided Node. It's not guaranteed
// that provided inode will be set. The attached inode will be returned.
func (g Guard) ChangeInode(n *Node, inode uint64) uint64 {
	return g.t.changeInode(n, inode)
}

// MvChild does the same job as MvChild. It is here for the sake of API
// completeness.
func (g Guard) MvChild(nSrc *Node, nameSrc string, nDst *Node, nameDst string) (*Node, bool) {
	return MvChild(nSrc, nameSrc, nDst, nameDst)
}

// Predicate defines the read or write operation on the node. Node passed
// as argument can be safely modified. Any predicate function must return true
// in order to commit the changes.
type Predicate func(Guard, *Node) bool

// Insert adds or replaces a node pointed by provided nodePath. If the node nodePath
// doesn't exist it is created and nodes between inherit file permissions from
// the first present node in the tree.
func Insert(entry *Entry) Predicate {
	return func(_ Guard, n *Node) bool {
		if !n.IsShadowed() && n.Entry.File.Inode == RootInodeID {
			n.Entry = entry
			n.Entry.File.Inode = RootInodeID
			return true
		}

		n.Entry = entry
		return true
	}
}

// Delete removes the node and all its children from the tree.
func Delete() Predicate {
	return func(_ Guard, _ *Node) bool {
		return false
	}
}

// Walk calls provided function on root note and all its children.
func Walk(f func(Guard, *Node)) Predicate {
	return func(g Guard, n *Node) bool {
		for stack := []*Node{n}; len(stack) != 0; {
			f(g, stack[0])

			stack = append(stack[1:], stack[0].children...)
		}

		return true
	}
}

// WalkPath behaves like Walk but also sends path to the node.
func WalkPath(f func(string, Guard, *Node)) Predicate {
	var subFn func(string, Guard, *Node)

	subFn = func(nodePath string, g Guard, n *Node) {
		// Call on root node.
		f(nodePath, g, n)

		for i := range n.children {
			childPath := path.Join(nodePath, n.children[i].Name)
			// Save some function calls for regural files.
			if len(n.children[i].children) == 0 {
				f(childPath, g, n.children[i])
			} else {
				subFn(childPath, g, n.children[i])
			}
		}
	}

	return func(g Guard, n *Node) bool {
		subFn("", g, n)
		return true
	}
}

// ExistCount stores the number of nodes that are proven to exist.
func ExistCount(n *int) Predicate {
	return Walk(func(_ Guard, nd *Node) {
		if nd.Entry != nil && nd.Entry.Virtual.Promise.Exist() {
			(*n)++
		}
	})
}

// ExistDiskSize stores the size of nodes that are proven to exist.
func ExistDiskSize(size *int64) Predicate {
	return Walk(func(_ Guard, n *Node) {
		if n.Entry != nil && n.Entry.Virtual.Promise.Exist() {
			*size += n.Entry.File.Size
		}
	})
}

// Count stores the total number of nodes in provided argument.
func Count(n *int) Predicate {
	return Walk(func(Guard, *Node) { (*n)++ })
}

// DiskSize stores the total size of nodes in provided argument.
func DiskSize(size *int64) Predicate {
	return Walk(func(_ Guard, n *Node) {
		if n.Entry != nil {
			*size += n.Entry.File.Size
		}
	})
}
