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

	// DirentType stores type of entry, ie fuse.DT_Dir or fuse.DT_File
	DirentType fuse.DirentType

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

	// debug should almost be the first statement, but to prevent spamming of
	// resource file lookups, this call is moved here
	defer debug(time.Now(), "Name="+n.Name, "ExternalPath="+n.ExternalPath)

	a.Size = n.attr.Size
	a.Mode = n.attr.Mode

	return nil
}

// getInfo gets Node info from Klient. This method should almost never be called.
func (n *Node) getInfo(a *fuse.Attr) error {
	req := struct{ Path string }{n.ExternalPath}
	res := fsGetInfoRes{}

	if err := n.Trip("fs.getInfo", req, &res); err != nil {
		return err
	}

	a.Size = uint64(res.Size)
	a.Mode = os.FileMode(res.Mode)

	return nil
}
