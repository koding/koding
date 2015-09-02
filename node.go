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

	// FullInternalPath is full path on locally mounted folder.
	InternalPath string

	// FullExternalPath is full path on user VM.
	ExternalPath string

	// attr is metadata for Fuse.
	attr *fuse.Attr
}

func NewNode(d *Dir, name string) *Node {
	return &Node{
		Transport:    d.Transport,
		RWMutex:      sync.RWMutex{},
		Name:         name,
		InternalPath: filepath.Join(d.InternalPath, name),
		ExternalPath: filepath.Join(d.ExternalPath, name),
		attr:         &fuse.Attr{},
	}
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

// getInfo gets metadata from Transport.
func (n *Node) getInfo() (*fsGetInfoRes, error) {
	req := struct{ Path string }{n.ExternalPath}
	res := fsGetInfoRes{}

	if err := n.Trip("fs.getInfo", req, &res); err != nil {
		return nil, err
	}

	if !res.Exists {
		return nil, fuse.ENOENT
	}

	return &res, nil
}
