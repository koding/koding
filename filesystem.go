package main

import (
	"bazil.org/fuse"
	"bazil.org/fuse/fs"
	"golang.org/x/net/context"
)

// FileSystem is equivalent to fuse.FS, ie filesystem to be mounted. FileSystem
// is a bit misleading since Fuse allows even folders to be mounted.
type FileSystem struct {
	Transport

	// ExternalMountPath is path of folder in user VM to be mounted locally.
	ExternalMountPath string

	// InternalMountPath is path of folder in local to serve as mount point.
	InternalMountPath string

	// MountName is identifier for mount.
	MountName string

	// MountOptions is slice of options for mounting Fuse.
	MountOptions []fuse.MountOption
}

// Root returns root for FileSystem. Required by Fuse.
func (f *FileSystem) Root() (fs.Node, error) {
	return nil, nil
}

// Statfs returns metadata for FileSystem. Required by Fuse.
func (f *FileSystem) Statfs(ctx context.Context, req *fuse.StatfsRequest, resp *fuse.StatfsResponse) error {
	return nil
}
