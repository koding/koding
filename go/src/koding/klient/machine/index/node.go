package index

import (
	"path/filepath"
	"strings"
)

type Node struct {
	Sub   map[string]*Node `json:"d,omitempty"`
	Entry *Entry           `json:"e,omitempty"`
}

func newNode() *Node {
	return &Node{
		Sub:   make(map[string]*Node),
		Entry: &Entry{},
	}
}

func (nd *Node) Add(name string, entry *Entry) {
	if name == "/" {
		nd.Entry = entry
		return
	}

	var node string

	for {
		node, name = split(name)

		sub, ok := nd.Sub[node]
		if !ok {
			sub = newNode()
			nd.Sub[node] = sub
		}

		if name == "" {
			sub.Entry = entry
			return
		}

		nd = sub
	}
}

func (nd *Node) Del(name string) {
	var node string

	for {
		node, name = split(name)

		if name == "" {
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

func (nd *Node) Count(maxsize int64) (count int) {
	if maxsize == 0 {
		return 0 // no-op
	}

	cur, stack := (*Node)(nil), []*Node{nd}

	for len(stack) != 0 {
		cur, stack = stack[0], stack[1:]

		if cur.Entry != nil && (maxsize < 0 || cur.Entry.Size <= maxsize) && cur != nd {
			count++
		}

		for _, nd := range cur.Sub {
			stack = append(stack, nd)
		}
	}

	return count
}

func (nd *Node) DiskSize(maxsize int64) (size int64) {
	if maxsize == 0 {
		return 0 // no-op
	}

	stack := []*Node{nd}

	for len(stack) != 0 {
		nd, stack = stack[0], stack[1:]

		if nd.Entry != nil && (maxsize < 0 || nd.Entry.Size <= maxsize) {
			size += nd.Entry.Size
		}

		for _, nd := range nd.Sub {
			stack = append(stack, nd)
		}
	}

	return size
}

func (nd *Node) ForEach(fn func(string, *Entry)) {
	type node struct {
		path string
		node *Node
	}

	n, stack := node{}, make([]node, 0, len(nd.Sub))

	for path, nd := range nd.Sub {
		stack = append(stack, node{
			path: path,
			node: nd,
		})
	}

	for len(stack) != 0 {
		n, stack = stack[0], stack[1:]

		for path, nd := range n.node.Sub {
			stack = append(stack, node{
				path: filepath.Join(n.path, path),
				node: nd,
			})
		}

		fn(n.path, n.node.Entry)
	}
}

func (nd *Node) Lookup(name string) (*Node, bool) {
	if name == "/" {
		return nd, true
	}

	var node string

	for {
		node, name = split(name)

		sub, ok := nd.Sub[node]
		if !ok {
			return nil, false
		}

		if name == "" {
			return sub, true
		}

		nd = sub
	}
}

func split(path string) (string, string) {
	if path[0] == '/' {
		path = path[1:]
	}

	if i := strings.IndexRune(path, '/'); i != -1 {
		return path[:i], path[i+1:]
	}

	return path, ""
}
