package main

import (
	"os"
	"path"
	"time"

	"bazil.org/fuse"
	"bazil.org/fuse/fs"
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
}

// Root returns root for FileSystem. Required by Fuse.
func (f *FileSystem) Root() (fs.Node, error) {
	defer debug(time.Now(), nil)

	n := NewNodeWithInitial(f.Transport)
	n.Name = path.Base(f.InternalMountPath)
	n.InternalPath = f.InternalMountPath
	n.ExternalPath = f.ExternalMountPath

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
		f.InternalMountPath,
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
