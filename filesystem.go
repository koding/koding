package main

import (
	"os"
	"path"
	"time"

	"bazil.org/fuse"
	"bazil.org/fuse/fs"
)

// FileSystem is equivalent to fuse.FS, ie file system to be mounted. The name
// file system is misleading since Fuse allows folders to be mounted.
type FileSystem struct {
	Transport

	// RemotePath is path to folder in user VM to be mounted locally.
	RemotePath string

	// LocalPath is path to folder in local to serve as mount point.
	LocalPath string

	// MountName is identifier for mount.
	MountName string
}

// Root returns root for FileSystem. Required by Fuse.
func (f *FileSystem) Root() (fs.Node, error) {
	defer debug(time.Now())

	n := NewNodeWithInitial(f.Transport)
	n.Name = path.Base(f.LocalPath)
	n.LocalPath = f.LocalPath
	n.RemotePath = f.RemotePath

	// TODO: use FileSystem#Statfs when it's implemented
	res, err := n.getInfo()
	if err != nil {
		return nil, err
	}

	n.attr.Size = uint64(res.Size)
	n.attr.Mode = os.FileMode(res.Mode)

	return NewDir(n), nil
}

// Statfs returns metadata for FileSystem. Required by Fuse.
// TODO: requires Klient to implement a method that returns disk level info.
// func (f *FileSystem) Statfs(ctx context.Context, req *fuse.StatfsRequest, resp *fuse.StatfsResponse) error {
//   return nil
// }

// Mount mounts folder on user VM as a volume.
func (f *FileSystem) Mount() error {
	c, err := fuse.Mount(
		f.LocalPath,
		fuse.FSName(f.MountName),
		fuse.Subtype(f.MountName),
		fuse.VolumeName(f.MountName),
		fuse.LocalVolume(),
	)
	if err != nil {
		return err
	}

	if err := fs.Serve(c, f); err != nil {
		return err
	}

	<-c.Ready

	return c.MountError
}
