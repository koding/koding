package fuse

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"sync/atomic"

	"koding/klient/machine/index"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	"golang.org/x/net/context"
)

// StatFS sets filesystem metadata.
//
// Required for fuse.FileSystem.
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

// LookUpInode finds entry in context of specific parent directory and sets
// its attributes. It assumes parent directory has already been seen.
//
// Required for fuse.FileSystem.
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

// GetInodeAttributes set attributes for a specified Node.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) GetInodeAttributes(ctx context.Context, op *fuseops.GetInodeAttributesOp) error {
	nd, _, ok := fs.get(op.Inode)
	if !ok {
		return fuse.ENOENT
	}

	op.Attributes = fs.attr(nd.Entry)

	return nil
}

// SetInodeAttributes sets specified attributes to file or directory.
//
// Required for fuse.FileSystem.
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

// MkDir creates new directory inside specified parent directory. It returns
// `fuse.EEXIST` if a file or directory already exists with specified name.
//
// Note: `mkdir` command checks if directory exists before calling this method,
// so you won't see the error from here if you're using `mkdir`.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) MkDir(ctx context.Context, op *fuseops.MkDirOp) error {
	dir, path, err := fs.getDir(op.Parent)
	if err != nil {
		return err
	}

	if _, ok := dir.Sub[op.Name]; ok {
		return fuse.EEXIST
	}

	path = filepath.Join(path, op.Name)

	op.Entry.Child, err = fs.mkdir(path, op.Mode)
	if err != nil {
		return err
	}

	op.Entry.Attributes = fs.newAttr(op.Mode)

	return fs.yield(ctx, path, index.ChangeMetaAdd|index.ChangeMetaLocal)
}

// CreateFile creates an empty file with specified name and mode. It returns an
// error if specified parent directory doesn't exist. but not if file already
// exists.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) CreateFile(ctx context.Context, op *fuseops.CreateFileOp) error {
	dir, path, err := fs.getDir(op.Parent)
	if err != nil {
		return err
	}

	if _, ok := dir.Sub[op.Name]; ok {
		return fuse.EEXIST
	}

	path = filepath.Join(path, op.Name)

	op.Entry.Child, err = fs.mkfile(path, op.Mode)
	if err != nil {
		return err
	}

	op.Entry.Attributes = fs.newAttr(op.Mode)

	return fs.yield(ctx, path, index.ChangeMetaAdd|index.ChangeMetaLocal)
}

// Rename changes a file or directory from old name and parent to new name and
// parent.
//
// Note if a new name already exists, we still go ahead and rename it. While
// the old and new entries are the same, we throw out the old one and create
// new entry for it.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) Rename(ctx context.Context, op *fuseops.RenameOp) error {
	oldDir, oldPath, err := fs.getDir(op.OldParent)
	if err != nil {
		return err
	}

	newDir, newPath, err := fs.getDir(op.NewParent)
	if err != nil {
		return err
	}

	oldNd, ok := oldDir.Sub[op.OldName]
	if !ok {
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

	entry := &index.Entry{
		Mode: oldDir.Entry.Mode,
	}

	id := fuseops.InodeID(atomic.LoadUint64(&oldNd.Entry.Aux))

	fs.mu.Lock()
	delete(fs.inodes, id)
	id = fs.add(newPath)
	fs.mu.Unlock()

	entry.Aux = uint64(id)

	fs.Remote.PromiseDel(oldPath)
	fs.Remote.PromiseAdd(newPath, entry)

	return nonil(
		fs.yield(ctx, oldPath, index.ChangeMetaLocal|index.ChangeMetaRemove),
		fs.yield(ctx, newPath, index.ChangeMetaLocal|index.ChangeMetaAdd),
	)
}

// RmDir deletes a directory from remote and list of live nodes.
//
// Note: `rm -r` calls Unlink method on each directory entry.
//
// Required for fuse.FileSystem.
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

// Unlink removes entry from specified parent directory.
//
// Required for fuse.FileSystem.
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

// OpenDir opens a directory, ie. indicates operations are to be done on this
// directory.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) OpenDir(ctx context.Context, op *fuseops.OpenDirOp) error {
	_, _, err := fs.getDir(op.Inode)
	return err
}

// ReleaseDirHandle removes a directory under the given handle ID for open ones.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) ReleaseDirHandle(ctx context.Context, op *fuseops.ReleaseDirHandleOp) error {
	return nil
}

// ReadDir reads entries in a specific directory.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) ReadDir(ctx context.Context, op *fuseops.ReadDirOp) error {
	dir, path, err := fs.getDir(op.Inode)
	if err != nil {
		return err
	}

	if op.Offset >= fuseops.DirOffset(len(dir.Sub)) {
		return fuse.EIO
	}

	files := make([]string, 0, len(dir.Sub))

	for name := range dir.Sub {
		files = append(files, name)
	}

	sort.Strings(files)

	files = files[int(op.Offset):]

	dirent := make([]*fuseutil.Dirent, 0, len(files))

	for i, file := range files {
		sub := dir.Sub[file]

		dirent = append(dirent, &fuseutil.Dirent{
			Offset: op.Offset + fuseops.DirOffset(i+1),
			Inode:  fs.lookupInodeID(path, file, sub.Entry),
			Name:   file,
			Type:   direntType(sub.Entry),
		})
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

// OpenFile opens a File, ie. indicates operations are to be done on this file.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) OpenFile(ctx context.Context, op *fuseops.OpenFileOp) error {
	_, h, err := fs.openInode(ctx, op.Inode)
	if err != nil {
		return err
	}

	op.KeepPageCache = false
	op.Handle = h

	return nil
}

// ReadFile reads contents of a specified file starting from specified offset.
// It returns `io.EIO` if specified offset is larger than the length of contents
// of the file.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) ReadFile(ctx context.Context, op *fuseops.ReadFileOp) error {
	f, err := fs.openHandle(op.Handle)
	if err != nil {
		return err
	}

	op.BytesRead, err = f.ReadAt(op.Dst, op.Offset)
	if err == io.EOF {
		err = nil // ignore io.EOF errors
	}
	return err
}

// WriteFile write specified contents to specified file at specified offset.
//
// Required for fuse.FileSystem.
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

// SyncFile sends file contents from local to remote.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) SyncFile(ctx context.Context, op *fuseops.SyncFileOp) error {
	f, err := fs.openHandle(op.Handle)
	if err != nil {
		return err
	}

	return f.Sync()
}

// ReleaseFileHandle releases file handle. It does not return errors even if it
// fails since this op doesn't affect anything.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) ReleaseFileHandle(_ context.Context, op *fuseops.ReleaseFileHandleOp) error {
	_ = fs.delHandle(op.Handle)
	return nil
}

func (fs *Filesystem) Destroy() {
	fs.mu.Lock()
	for _, f := range fs.handles {
		_ = f.Close()
	}
	fs.handles = make(map[fuseops.HandleID]*os.File)
	fs.mu.Unlock()
}

func Umount(dir string) error {
	if runtime.GOOS == "linux" {
		return fuse.Unmount(dir)
	}

	// Under Darwin fuse.Umount uses syscall.Umount without syscall.MNT_FORCE flag,
	// so we replace that implementation with diskutil.
	p, err := exec.Command("diskutil", "unmount", "force", dir).CombinedOutput()
	if err != nil {
		return fmt.Errorf("%s: %s", err, bytes.TrimSpace(p))
	}

	return nil
}
