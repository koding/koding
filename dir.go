package main

import (
	"bazil.org/fuse"
	"bazil.org/fuse/fs"
	"golang.org/x/net/context"
)

type Dir struct {
	*Node
}

// Lookup returns file or dir if exists; fuse.EEXIST if not. Required by Fuse.
func (d *Dir) Lookup(ctx context.Context, name string) (fs.Node, error) {
	return nil, nil
}

// ReadDirAll returns metadata for files and directories. Required by Fuse.
func (d *Dir) ReadDirAll(ctx context.Context) ([]fuse.Dirent, error) {
	return nil, nil
}
