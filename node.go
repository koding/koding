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

	// Path is the location of file/dir on FileSystem.
	Path string

	// Name is the identifier.
	Name string

	// FullPath is Path and Name.
	FullPath string

	// attr is metadata.
	attr *fuse.Attr
}

// Attr returns metadata. Required by Fuse.
func (n *Node) Attr(ctx context.Context, a *fuse.Attr) error {
	return nil
}
