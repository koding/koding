package main

import (
	"sync"

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
	return &Node{
		Transport: t,
		RWMutex:   sync.RWMutex{},
	}
}

// Attr returns metadata. Required by Fuse.
func (n *Node) Attr(ctx context.Context, a *fuse.Attr) error {
	return nil
}
