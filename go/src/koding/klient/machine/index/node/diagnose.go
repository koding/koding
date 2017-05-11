package node

import (
	"fmt"
)

// Diagnose checks tree looking for broken filesystem invariants. It returns
// a list of found problems. Each of them should be considered critical since
// they indicate broken logic.
func (t *Tree) Diagnose() []string {
	var s []string

	// Find all Nodes that are present in the tree.
	live := t.dft()

	// Special case where we handle nil values.
	if s = t.diagNilVal(live); len(s) > 0 {
		return s
	}

	diags := []func(map[*Node]int) []string{
		t.diagZeroMode,
		t.diagRoot,
		t.diagNonReg,
		t.diagMinRootID,
		t.diagInodeMatch,
		t.diagOrphans,
		t.diagNChild,
		t.diagTimes,
		t.diagNoDirNoChild,
	}
	for _, diag := range diags {
		s = append(s, diag(live)...)
	}

	return s
}

// dft uses depth first traversal algorithm to visit all nodes inside the tree
// the returned map will contain all found items with the number of child nodes
// pointing to them.
func (t *Tree) dft() map[*Node]int {
	visited := make(map[*Node]int)

	var dft func(*Node)
	dft = func(n *Node) {
		if n == nil {
			return
		}

		// Mark node as visited.
		if count, ok := visited[n]; ok {
			visited[n] = count + 1
			return
		}
		visited[n] = 1

		family := append([]*Node{n.parent}, n.children...)
		for _, sub := range family {
			dft(sub)
		}
	}

	// Run recursively for all nodes.
	dft(t.root)

	return visited
}

// dialNilVal checks if all Nodes in tree are initialized.
func (t *Tree) diagNilVal(live map[*Node]int) (s []string) {
	visited := make(map[*Node]struct{})
	for i, n := range t.inodes {
		visited[n] = struct{}{}
		if n == nil {
			s = append(s, fmt.Sprintf("nil node under %d inode value", i))
		}
	}

	if len(s) > 0 {
		return s
	}

	for n, p := range live {
		visited[n] = struct{}{}
		if n == nil {
			s = append(s, fmt.Sprintf("nil node inside the tree referenced by %d nodes", p))
		}
	}

	if len(s) > 0 {
		return s
	}

	for n := range visited {
		if n.Entry == nil {
			s = append(s, fmt.Sprintf("nil entry inside node %s", n.Name))
		}
	}

	return s
}

// diagZeroVal looks for invalid zero file modes present in the tree.
func (t *Tree) diagZeroMode(_ map[*Node]int) (s []string) {
	for _, n := range t.inodes {
		if n.Entry.File.Mode == 0 {
			s = append(s, fmt.Sprintf("zero value mode of node %s", n.Name))
		}
	}

	return s
}

// diagRoot checks if `root` Node is set properly.
func (t *Tree) diagRoot(_ map[*Node]int) (s []string) {
	if in := t.root.Entry.File.Inode; in != RootInodeID {
		s = append(s, fmt.Sprintf("root node has invalid inode number %d", in))
	}

	if !t.root.Entry.File.Mode.IsDir() {
		s = append(s, "root node is not a directory")
	}

	return s
}

// diagNonReg checks if all Nodes present in the tree are registered to inodes map.
func (t *Tree) diagNonReg(live map[*Node]int) (s []string) {
	for n := range live {
		in := n.Entry.File.Inode
		if _, ok := t.inodes[in]; !ok {
			s = append(s, fmt.Sprintf("node %s with inode %d is not indexed", n.Name, in))
		}
	}

	return s
}

// diagMinRootID checks if all registered nodes have their inodes greater or
// equal to RootInodeID.
func (t *Tree) diagMinRootID(_ map[*Node]int) (s []string) {
	for i, n := range t.inodes {
		if i < RootInodeID {
			s = append(s, fmt.Sprintf("node %s has invalid inode value %d", n.Name, i))
		}
	}

	return s
}

// diagInodeMatch checks if inode key stored in map matches inode field stored
// in map's value Node.
func (t *Tree) diagInodeMatch(_ map[*Node]int) (s []string) {
	for i, n := range t.inodes {
		in := n.Entry.File.Inode
		if i != in {
			s = append(s, fmt.Sprintf(
				"indexed inode(%d) and stored one(%d) does not match for node %s", i, in, n.Name))
		}
	}

	return s
}

// diagOrphans checks if all Nodes not present in `live` tree are orphans that
// have non `root` parent. Also, they all have to be marked as deleted.
func (t *Tree) diagOrphans(live map[*Node]int) (s []string) {
	isOrphan := func(n *Node) bool {
		visited := make(map[*Node]struct{})

		for n != t.root {
			if _, ok := visited[n]; ok {
				s = append(s, fmt.Sprintf("loop detected in %s node", n.Name))
				return false
			}
			visited[n] = struct{}{}

			if n.parent == nil {
				return true
			}

			n = n.parent
		}

		return false
	}

	for _, n := range t.inodes {
		orphan := isOrphan(n)

		switch _, ok := live[n]; {
		case ok && orphan:
			// File is an orphan but is present in the tree. This would be
			// possible if tree supported hard links.
			s = append(s, fmt.Sprintf("orphan node %s present in the tree", n.Name))
		case !ok && orphan:
			// File is not present in the tree and it's an orphan so it must be
			// marked as deleted.
			if !n.Entry.Virtual.Promise.Deleted() {
				s = append(s, fmt.Sprintf("orphan node %s is not marked as deleted", n.Name))
			}
		case ok && !orphan:
			// File is present in the tree. OK.
		case !ok && !orphan:
			// File is not preset in the tree but it claims it is connected to
			// root inode. Which should be impossible.
			s = append(s, fmt.Sprintf("node %s is not marked as an orphan", n.Name))
		}
	}

	return s
}

// diagNChild checks if number of children created by DFT algorithm matches the
// actual number of children node have.
func (t *Tree) diagNChild(live map[*Node]int) (s []string) {
	for n, cn := range live {
		if n.parent != nil || n == t.root {
			cn-- // Remove parent reference.
		}

		if cn != n.ChildN() {
			s = append(s, fmt.Sprintf("node %s is referenced by too many nodes(%d)", n.Name, cn))
		}
	}

	return s
}

// diagTimes checks if times are set correctly and if change time was before
// or during modification time.
func (t *Tree) diagTimes(_ map[*Node]int) (s []string) {
	for _, n := range t.inodes {
		if n.Entry.File.CTime == 0 {
			s = append(s, fmt.Sprintf("change time of node %s is not set", n.Name))
			continue
		}

		if n.Entry.File.MTime == 0 {
			s = append(s, fmt.Sprintf("modification time of node %s is not set", n.Name))
			continue
		}

		if n.Entry.File.MTime > n.Entry.File.CTime {
			s = append(s, fmt.Sprintf("node %s modification time is greater than change one", n.Name))
		}
	}

	return s
}

// diagNoDirNoChild checks if nodes with non directory mode have no children.
func (t *Tree) diagNoDirNoChild(_ map[*Node]int) (s []string) {
	for _, n := range t.inodes {
		if !n.Entry.File.Mode.IsDir() && n.ChildN() > 0 {
			s = append(s, fmt.Sprintf("node %s is not a directory but has %d children", n.Name, n.ChildN()))
		}
	}

	return s
}
