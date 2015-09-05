package main

import (
	"path/filepath"
	"strings"
	"sync"

	"bazil.org/fuse"
	"golang.org/x/net/context"
)

// Node is a generic name for File or Dir. It contains common fields and
// implements common methods between the two.
type Node struct {
	Transport
	sync.RWMutex

	// DirentType stores type of entry, ie fuse.DT_Dir or fuse.DT_File.
	DirentType fuse.DirentType

	// Parent is the parent of node, ie folder that holds this node.
	Parent *Node

	// Name is the identifier of file or directory.
	Name string

	// LocalPath is full path on locally mounted folder.
	LocalPath string

	// RemotePath is full path on user VM.
	RemotePath string

	// attr is metadata for Fuse.
	attr *fuse.Attr
}

func NewNode(d *Dir, name string) *Node {
	n := NewNodeWithInitial(d.Transport)
	n.Name = name
	n.RemotePath = filepath.Join(d.RemotePath, name)
	n.LocalPath = filepath.Join(d.LocalPath, name)

	return n
}

func NewNodeWithInitial(t Transport) *Node {
	return &Node{Transport: t, RWMutex: sync.RWMutex{}, attr: &fuse.Attr{}}
}

// Attr returns metadata. Required by Fuse.
func (n *Node) Attr(ctx context.Context, a *fuse.Attr) error {
	n.RLock()
	defer n.RUnlock()

	// TODO: how to deal with resource files
	if strings.HasPrefix(n.Name, "._") {
		return nil
	}

	a.Size = n.attr.Size
	a.Mode = n.attr.Mode

	return nil
}

// getInfo gets metadata from Transport. Returns fuse.EEXIST if node doesn't
// exist. Required by Fuse.
func (n *Node) getInfo() (*fsGetInfoRes, error) {
	req := struct{ Path string }{n.RemotePath}
	res := fsGetInfoRes{}
	if err := n.Trip("fs.getInfo", req, &res); err != nil {
		return nil, err
	}

	if !res.Exists {
		return nil, fuse.ENOENT
	}

	return &res, nil
}
