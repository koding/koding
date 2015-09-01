package main

import (
	"os"
	"strings"
	"sync"
	"time"

	"bazil.org/fuse"
	"golang.org/x/net/context"
)

// Node is a generic name for File or Dir. It contains common fields and
// implements common methods between the two.
type Node struct {
	Transport
	sync.RWMutex

	// Parent is the parent of node, ie folder that holds this node.
	Parent *Node

	// Name is the identifier.
	Name string

	// FullInternalPath is full path on mounted folder.
	InternalPath string

	// FullExternalPath is full path on user VM.
	ExternalPath string

	// attr is metadata.
	attr *fuse.Attr
}

func NewNode(t Transport) *Node {
	return &Node{Transport: t, RWMutex: sync.RWMutex{}, attr: &fuse.Attr{}}
}

// Attr returns metadata. Required by Fuse.
func (n *Node) Attr(ctx context.Context, a *fuse.Attr) error {
	n.Lock()
	defer n.Unlock()

	// TODO: how to deal with resource files
	if strings.HasPrefix(n.Name, "._") {
		return nil
	}

	defer debug(time.Now(), "Name="+n.Name, "ExternalPath="+n.ExternalPath)

	req := struct{ Path string }{n.ExternalPath}
	res := fsGetInfoRes{}

	// TODO: this should be set by Dir#ReadAllDir
	if err := n.Trip("fs.getInfo", req, &res); err != nil {
		return err
	}

	a.Size = uint64(res.Size)
	a.Mode = os.FileMode(res.Mode)

	return nil
}
