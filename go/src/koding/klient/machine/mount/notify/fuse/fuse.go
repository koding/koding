package fuse

import (
	"os"
	"path/filepath"

	"koding/klient/machine/index"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	"golang.org/x/net/context"
)

func (fs *Filesystem) StatFS(ctx context.Context, op *fuseops.StatFSOp) error {
	if fs.Disk == nil {
		return fuse.ENOENT
	}

	op.Blocks = fs.Disk.BlocksTotal
	op.BlockSize = fs.Disk.BlockSize
	op.BlocksFree = fs.Disk.BlocksFree
	op.BlocksAvailable = fs.Disk.BlocksTotal - fs.Disk.BlocksUsed

	return nil
}

func (fs *Filesystem) LookUpInode(ctx context.Context, op *fuseops.LookUpInodeOp) error {
	dir, path, err := fs.getDir(op.Parent)
	if err != nil {
		return err
	}

	nd, ok := dir.Sub[op.Name]
	if !ok {
		return fuse.ENOENT
	}

	op.Entry.Child = fs.lookupInodeID(path, op.Name, nd.Entry)
	op.Entry.Attributes = fs.attr(nd.Entry)

	return nil
}

func (fs *Filesystem) GetInodeAttributes(ctx context.Context, op *fuseops.GetInodeAttributesOp) error {
	nd, _, ok := fs.get(op.Inode)
	if !ok {
		return fuse.ENOENT
	}

	op.Attributes = fs.attr(nd.Entry)

	return nil
}

func (fs *Filesystem) SetInodeAttributes(ctx context.Context, op *fuseops.SetInodeAttributesOp) error {
	nd, path, ok := fs.get(op.Inode)
	if !ok {
		return fuse.ENOENT
	}

	f, err := fs.openFile(ctx, path)
	if err != nil {
		return err
	}

	op.Attributes = fs.attr(nd.Entry)

	if op.Size != nil {
		if err := f.Truncate(int64(*op.Size)); err != nil {
			return nonil(err, f.Close())
		}

		op.Attributes.Size = *op.Size
	}

	if op.Mode != nil {
		if err := f.Chmod(*op.Mode); err != nil {
			return nonil(err, f.Close())
		}

		op.Attributes.Mode = *op.Mode
	}

	if err := f.Close(); err != nil {
		return err
	}

	if op.Atime != nil || op.Mtime != nil {
		if op.Atime != nil {
			op.Attributes.Atime = *op.Atime
		}

		if op.Mtime != nil {
			op.Attributes.Mtime = *op.Mtime
		}

		if err := os.Chtimes(path, op.Attributes.Atime, op.Attributes.Mtime); err != nil {
			return err
		}
	}

	return fs.yield(ctx, path, index.ChangeMetaLocal|index.ChangeMetaUpdate)
}

func (fs *Filesystem) MkDir(ctx context.Context, op *fuseops.MkDirOp) error {
	dir, path, err := fs.getDir(op.Parent)
	if err != nil {
		return err
	}

	if _, ok := dir.Sub[op.Name]; ok {
		return fuse.EEXIST
	}

	path = filepath.Join(path, op.Name)

	if err := fs.mkdir(path, op.Mode); err != nil {
		return err
	}

	op.Entry.Child = fs.mkInodeID(path)
	op.Entry.Attributes = fs.newAttr(op.Mode)

	return fs.yield(ctx, path, index.ChangeMetaAdd|index.ChangeMetaLocal)
}

func (fs *Filesystem) CreateFile(ctx context.Context, op *fuseops.CreateFileOp) error {
	dir, path, err := fs.getDir(op.Parent)
	if err != nil {
		return err
	}

	if _, ok := dir.Sub[op.Name]; ok {
		return fuse.EEXIST
	}

	path = filepath.Join(path, op.Name)

	if err := fs.touch(ctx, path, op.Mode); err != nil {
		return err
	}

	op.Entry.Child = fs.mkInodeID(path)
	op.Entry.Attributes = fs.newAttr(op.Mode)

	return fs.yield(ctx, path, index.ChangeMetaAdd|index.ChangeMetaLocal)
}

func (fs *Filesystem) Rename(ctx context.Context, op *fuseops.RenameOp) error {
	oldDir, oldPath, err := fs.getDir(op.OldParent)
	if err != nil {
		return err
	}

	newDir, newPath, err := fs.getDir(op.NewParent)
	if err != nil {
		return err
	}

	if _, ok := oldDir.Sub[op.OldName]; !ok {
		return fuse.ENOENT
	}

	if _, ok := newDir.Sub[op.NewName]; ok {
		return fuse.EEXIST
	}

	oldPath = filepath.Join(oldPath, op.OldName)
	newPath = filepath.Join(newPath, op.NewName)

	if err := fs.move(ctx, oldPath, newPath); err != nil {
		return err
	}

	if err := fs.yield(ctx, oldPath, index.ChangeMetaLocal|index.ChangeMetaRemove); err != nil {
		return err
	}

	return fs.yield(ctx, newPath, index.ChangeMetaLocal|index.ChangeMetaAdd)
}

func (fs *Filesystem) RmDir(ctx context.Context, op *fuseops.RmDirOp) error {
	dir, path, err := fs.getDir(op.Parent)
	if err != nil {
		return err
	}

	nd, ok := dir.Sub[op.Name]
	if !ok {
		return fuse.ENOENT
	}

	if !isdir(nd.Entry) {
		return fuse.EIO
	}

	path = filepath.Join(path, op.Name)

	if err := fs.rm(nd, path); err != nil {
		return err
	}

	return fs.yield(ctx, path, index.ChangeMetaLocal|index.ChangeMetaRemove)
}

func (fs *Filesystem) Unlink(ctx context.Context, op *fuseops.UnlinkOp) error {
	dir, path, err := fs.getDir(op.Parent)
	if err != nil {
		return err
	}

	nd, ok := dir.Sub[op.Name]
	if !ok {
		return fuse.ENOENT
	}

	path = filepath.Join(path, op.Name)

	if err := fs.rm(nd, path); err != nil {
		return err
	}

	return fs.yield(ctx, path, index.ChangeMetaLocal|index.ChangeMetaRemove)
}

func (fs *Filesystem) OpenDir(ctx context.Context, op *fuseops.OpenDirOp) error {
	_, _, err := fs.getDir(op.Inode)
	return err
}

func (fs *Filesystem) ReadDir(ctx context.Context, op *fuseops.ReadDirOp) error {
	dir, path, err := fs.getDir(op.Inode)
	if err != nil {
		return err
	}

	dirent, err := fs.readdir(dir, path, op.Offset)
	if err != nil {
		return err
	}

	sum := 0

	// TODO(rjeczalik): we can estimate how many entries to return by
	// looking at op.Dst size.
	for _, dir := range dirent {
		n := fuseutil.WriteDirent(op.Dst[sum:], *dir)
		if n == 0 {
			break
		}

		sum += n
	}

	op.BytesRead = sum

	return nil
}

func (fs *Filesystem) OpenFile(ctx context.Context, op *fuseops.OpenFileOp) error {
	_, h, err := fs.openInode(ctx, op.Inode)
	if err != nil {
		return err
	}

	op.KeepPageCache = false
	op.Handle = h

	return nil
}

func (fs *Filesystem) ReadFile(ctx context.Context, op *fuseops.ReadFileOp) error {
	f, err := fs.openHandle(op.Handle)
	if err != nil {
		return err
	}

	op.BytesRead, err = f.ReadAt(op.Dst, op.Offset)
	return err
}

func (fs *Filesystem) WriteFile(ctx context.Context, op *fuseops.WriteFileOp) error {
	f, err := fs.openHandle(op.Handle)
	if err != nil {
		return err
	}

	if _, err = f.WriteAt(op.Data, op.Offset); err != nil {
		return err
	}

	return fs.yield(ctx, f.Name(), index.ChangeMetaLocal|index.ChangeMetaUpdate)
}

func (fs *Filesystem) SyncFile(ctx context.Context, op *fuseops.SyncFileOp) error {
	f, err := fs.openHandle(op.Handle)
	if err != nil {
		return err
	}

	return f.Sync()
}

func (fs *Filesystem) ReleaseFileHandle(_ context.Context, op *fuseops.ReleaseFileHandleOp) error {
	return fs.delHandle(op.Handle)
}

func (fs *Filesystem) Destroy() {}
