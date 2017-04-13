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

	"koding/klient/machine/index"
	"koding/klient/machine/index/node"

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
	op.IoSize = uint32(fs.Disk.IOSize)

	return nil
}

// LookUpInode finds entry in context of specific parent directory and sets
// its attributes. It assumes parent directory has already been seen.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) LookUpInode(ctx context.Context, op *fuseops.LookUpInodeOp) error {
	dir, rel, err := fs.getDir(op.Parent)
	if err != nil {
		return err
	}

	nd, ok := dir.Sub[op.Name]
	if !ok || nd.Deleted() {
		return fuse.ENOENT
	}

	op.Entry.Child = fs.lookupInodeID(rel, op.Name, nd.Entry)
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
	nd, rel, ok := fs.get(op.Inode)
	if !ok {
		return fuse.ENOENT
	}

	f, err := fs.openFile(ctx, rel, nd.Entry.Mode())
	if err != nil {
		return err
	}

	op.Attributes = fs.attr(nd.Entry)

	if op.Size != nil {
		if err := f.Truncate(int64(*op.Size)); err != nil {
			return nonil(err, f.Close())
		}

		op.Attributes.Size = *op.Size
		nd.Entry.SetSize(int64(*op.Size))
	}

	if op.Mode != nil && *op.Mode != 0 {
		if err := f.Chmod(*op.Mode); err != nil {
			return nonil(err, f.Close())
		}

		op.Attributes.Mode = *op.Mode
		nd.Entry.SetMode(*op.Mode)
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
			nd.Entry.SetMTime(op.Mtime.UnixNano())
		}

		if err := os.Chtimes(f.Name(), op.Attributes.Atime, op.Attributes.Mtime); err != nil {
			return err
		}
	}

	fs.commit(rel, index.ChangeMetaLocal|index.ChangeMetaUpdate)

	return nil
}

// MkDir creates new directory inside specified parent directory. It returns
// `fuse.EEXIST` if a file or directory already exists with specified name.
//
// Note: `mkdir` command checks if directory exists before calling this method,
// so you won't see the error from here if you're using `mkdir`.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) MkDir(ctx context.Context, op *fuseops.MkDirOp) error {
	dir, rel, err := fs.getDir(op.Parent)
	if err != nil {
		return err
	}

	if _, ok := dir.Sub[op.Name]; ok {
		return fuse.EEXIST
	}

	path := filepath.Join(rel, op.Name)

	op.Entry.Child, err = fs.mkdir(path, op.Mode)
	if err != nil {
		return err
	}

	op.Entry.Attributes = fs.newAttr(op.Mode)

	fs.commit(path, index.ChangeMetaAdd|index.ChangeMetaLocal)

	return nil
}

// CreateFile creates an empty file with specified name and mode. It returns an
// error if specified parent directory doesn't exist. but not if file already
// exists.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) CreateFile(ctx context.Context, op *fuseops.CreateFileOp) error {
	dir, rel, err := fs.getDir(op.Parent)
	if err != nil {
		return err
	}

	if nd, ok := dir.Sub[op.Name]; ok && !nd.Deleted() {
		return fuse.EEXIST
	}

	path := filepath.Join(rel, op.Name)

	op.Entry.Child, op.Handle, err = fs.mkfile(path, op.Mode)
	if err != nil {
		return err
	}

	op.Entry.Attributes = fs.newAttr(op.Mode)

	fs.commit(path, index.ChangeMetaAdd|index.ChangeMetaLocal)

	return nil
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
	if !ok || oldNd.Deleted() {
		return fuse.ENOENT
	}

	if newNd, ok := newDir.Sub[op.NewName]; ok && newNd.IsDir() {
		return fuse.EEXIST
	}

	oldPath = filepath.Join(oldPath, op.OldName)
	newPath = filepath.Join(newPath, op.NewName)

	if err := fs.move(ctx, oldPath, newPath); err != nil {
		return err
	}

	entry := oldNd.Entry.Clone()

	fs.mu.Lock()
	fs.inodes[fuseops.InodeID(entry.Inode())] = newPath
	fs.mu.Unlock()

	fs.Index.PromiseDel(oldPath, oldNd)
	fs.Index.PromiseAdd(newPath, entry)

	fs.commit(oldPath, index.ChangeMetaLocal|index.ChangeMetaRemove)
	fs.commit(newPath, index.ChangeMetaLocal|index.ChangeMetaAdd)

	return nil
}

// RmDir deletes a directory from remote and list of live nodes.
//
// Note: `rm -r` calls Unlink method on each directory entry.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) RmDir(ctx context.Context, op *fuseops.RmDirOp) error {
	dir, rel, err := fs.getDir(op.Parent)
	if err != nil {
		return err
	}

	nd, ok := dir.Sub[op.Name]
	if !ok || nd.Deleted() {
		return fuse.ENOENT
	}

	if !isdir(nd.Entry) {
		return fuse.EIO
	}

	path := filepath.Join(rel, op.Name)

	if err := fs.rm(ctx, nd, path); err != nil {
		return err
	}

	fs.commit(path, index.ChangeMetaLocal|index.ChangeMetaRemove)

	return nil
}

// Unlink removes entry from specified parent directory.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) Unlink(ctx context.Context, op *fuseops.UnlinkOp) error {
	dir, rel, err := fs.getDir(op.Parent)
	if err != nil {
		return err
	}

	nd, ok := dir.Sub[op.Name]
	if !ok || nd.Deleted() {
		return fuse.ENOENT
	}

	return fs.unlink(ctx, nd, filepath.Join(rel, op.Name))
}

// ForgotInode removes a file specified by an inode ID if the file was previously
// marked for an unlink.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) ForgetInode(ctx context.Context, op *fuseops.ForgetInodeOp) error {
	nd, rel, ok := fs.get(op.Inode)
	if !ok {
		return nil // no-op
	}

	if nd.Entry.HasPromise(node.EntryPromiseUnlink) {
		return fs.rm(ctx, nd, rel)
	}

	return nil
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
	dir, rel, err := fs.getDir(op.Inode)
	if err != nil {
		return err
	}

	files := make([]string, 0, len(dir.Sub))

	for name, nd := range dir.Sub {
		if !nd.Deleted() {
			files = append(files, name)
		}
	}

	if n := int(op.Offset); n > len(files) {
		return fuse.EIO
	} else if n == len(files) {
		return nil
	}

	sort.Strings(files)

	files = files[int(op.Offset):]

	dirent := make([]*fuseutil.Dirent, 0, len(files))

	for i, file := range files {
		sub := dir.Sub[file]

		dirent = append(dirent, &fuseutil.Dirent{
			Offset: op.Offset + fuseops.DirOffset(i+1),
			Inode:  fs.lookupInodeID(rel, file, sub.Entry),
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
	f, nd, err := fs.openHandleNode(op.Handle)
	if err != nil {
		return err
	}

	if _, err = f.WriteAt(trimRightNull(op.Data), op.Offset); err != nil {
		return err
	}

	updateSize(f, nd)

	fs.commit(fs.rel(f.Name()), index.ChangeMetaLocal|index.ChangeMetaUpdate)

	return nil
}

// SyncFile sends file contents from local to remote.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) SyncFile(ctx context.Context, op *fuseops.SyncFileOp) error {
	f, nd, err := fs.openHandleNode(op.Handle)
	if err != nil {
		return err
	}

	return fs.update(ctx, f, nd)
}

// FlushFile yields file updates on a locally cached file.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) FlushFile(ctx context.Context, op *fuseops.FlushFileOp) error {
	if op.Handle == 0 {
		return nil
	}

	f, nd, err := fs.openHandleNode(op.Handle)
	if err != nil {
		return err
	}

	err = f.Sync()
	updateSize(f, nd)

	return err
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

// Umount unmounts FUSE filesystem.
func Umount(dir string) error {
	umountCmd := func(name string, args ...string) error {
		if p, err := exec.Command(name, args...).CombinedOutput(); err != nil {
			return fmt.Errorf("%s: %s", err, bytes.TrimSpace(p))
		}

		return nil
	}

	if runtime.GOOS == "linux" {
		if err := fuse.Unmount(dir); err != nil {
			return umountCmd("fusermount", "-uz", dir) // Try lazy umount.
		}
		return nil
	}

	// Under Darwin fuse.Umount uses syscall.Umount without syscall.MNT_FORCE flag,
	// so we replace that implementation with diskutil.
	return umountCmd("diskutil", "unmount", "force", dir)
}
