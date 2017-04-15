package fuse

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

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
func (fs *Filesystem) LookUpInode(_ context.Context, op *fuseops.LookUpInodeOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Parent), func(_ node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		if child := n.GetChild(op.Name); child.Exist() {
			op.Entry.Child = fuseops.InodeID(child.Entry.Virtual.Inode)
			op.Entry.Attributes = fs.attr(child.Entry)
			return
		}

		err = fuse.ENOENT
	})

	return err
}

// GetInodeAttributes gets attributes of a node pointed by provided inode ID.
func (fs *Filesystem) GetInodeAttributes(_ context.Context, op *fuseops.GetInodeAttributesOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Inode), func(_ node.Guard, n *node.Node) {
		if n.Exist() {
			op.Attributes = fs.attr(n.Entry)
			return
		}

		err = fuse.ENOENT
	})

	return
}

// SetInodeAttributes sets specified attributes to file or directory.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) SetInodeAttributes(ctx context.Context, op *fuseops.SetInodeAttributesOp) (err error) {
	var rel string
	fs.Index.Tree().DoInode(uint64(op.Inode), func(_ node.Guard, n *node.Node) {
		if n == nil || !n.Entry.Virtual.Promise.Exist() {
			err = fuse.ENOENT
			return
		}

		rel := n.Path()

		var f *os.File
		if f, err = fs.openFile(ctx, rel, n.Entry.File.Mode); err != nil {
			return
		}

		op.Attributes = fs.attr(n.Entry)
		if op.Size != nil {
			if err = f.Truncate(int64(*op.Size)); err != nil {
				f.Close()
				return
			}
			op.Attributes.Size = *op.Size
		}

		if op.Mode != nil && *op.Mode != 0 {
			if err = f.Chmod(*op.Mode); err != nil {
				f.Close()
				return
			}
			op.Attributes.Mode = *op.Mode
		}

		if err = f.Close(); err != nil {
			return
		}

		if op.Atime != nil || op.Mtime != nil {
			if op.Atime != nil {
				op.Attributes.Atime = *op.Atime
			}

			if op.Mtime != nil {
				op.Attributes.Mtime = *op.Mtime
			}

			if err = os.Chtimes(f.Name(), op.Attributes.Atime, op.Attributes.Mtime); err != nil {
				return
			}
		}

		n.Entry.File.MTime = op.Attributes.Mtime.UnixNano()
		n.Entry.File.Mode = op.Attributes.Mode
		n.Entry.File.Size = int64(op.Attributes.Size)
	})

	if err == nil {
		fs.commit(rel, index.ChangeMetaLocal|index.ChangeMetaUpdate)
	}

	return
}

// MkDir creates new directory inside specified parent directory. It returns
// `fuse.EEXIST` if a file or directory already exists with specified name.
//
// Note: `mkdir` command checks if directory exists before calling this method,
// so you won't see the error from here if you're using `mkdir`.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) MkDir(ctx context.Context, op *fuseops.MkDirOp) (err error) {
	var path string
	fs.Index.Tree().DoInode(uint64(op.Parent), func(g node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		if child := n.GetChild(op.Name); child != nil && child.Entry.Virtual.Promise.Exist() {
			err = fuse.EEXIST
			return
		}

		path = filepath.Join(n.Path(), op.Name)
		if err = os.MkdirAll(filepath.Join(fs.CacheDir, path), op.Mode); err != nil {
			return
		}

		child := node.NewNodeEntry(op.Name, node.NewEntry(0, op.Mode|os.ModeDir))
		child.Entry.Virtual.RefCount++
		g.AddChild(n, child)
		child.PromiseAdd()

		op.Entry.Attributes = fs.newAttr(op.Mode)
	})

	if err == nil {
		fs.commit(path, index.ChangeMetaAdd|index.ChangeMetaLocal)
	}

	return
}

// CreateFile creates an empty file with specified name and mode. It returns an
// error if specified parent directory doesn't exist. but not if file already
// exists.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) CreateFile(ctx context.Context, op *fuseops.CreateFileOp) (err error) {
	var path string
	fs.Index.Tree().DoInode(uint64(op.Parent), func(g node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		if child := n.GetChild(op.Name); child != nil && child.Entry.Virtual.Promise.Exist() {
			err = fuse.EEXIST
			return
		}

		path = filepath.Join(n.Path(), op.Name)
		abs := filepath.Join(fs.CacheDir, path)
		if err = os.MkdirAll(filepath.Dir(abs), 0755); err != nil {
			return
		}

		var f *os.File
		if f, err = os.Create(abs); err != nil {
			return
		}

		_ = f.Chmod(op.Mode)

		child := node.NewNodeEntry(op.Name, node.NewEntry(0, op.Mode))
		child.Entry.Virtual.RefCount++
		g.AddChild(n, child)
		child.PromiseAdd()

		op.Entry.Attributes = fs.newAttr(op.Mode)
		op.Handle = fs.addHandle(fuseops.InodeID(child.Entry.Virtual.Inode), f)
	})

	if err == nil {
		fs.commit(path, index.ChangeMetaAdd|index.ChangeMetaLocal)
	}

	return
}

// Rename changes a file or directory from old name and parent to new name and
// parent.
//
// Note if a new name already exists, we still go ahead and rename it. While
// the old and new entries are the same, we throw out the old one and create
// new entry for it.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) Rename(ctx context.Context, op *fuseops.RenameOp) (err error) {
	var oldPath, newPath string
	fs.Index.Tree().DoInode2(uint64(op.OldParent), uint64(op.NewParent),
		func(g node.Guard, oldN, newN *node.Node) {
			if err = checkDir(oldN); err != nil {
				return
			}
			if err = checkDir(newN); err != nil {
				return
			}

			oldChild := oldN.GetChild(op.OldName)
			if oldChild == nil || !oldChild.Entry.Virtual.Promise.Exist() {
				err = fuse.ENOENT
				return
			}

			newChild := newN.GetChild(op.NewName)
			if newChild != nil && newChild.Entry.Virtual.Promise.Exist() {
				if newChild.Entry.File.Mode.IsDir() != oldChild.Entry.File.Mode.IsDir() {
					err = fuse.EINVAL
					return
				}

				if newChild.Entry.File.Mode.IsDir() && newChild.ChildN() != 0 {
					err = fuse.ENOTEMPTY
					return
				}
			}

			oldPath = filepath.Join(oldN.Path(), op.OldName)
			newPath = filepath.Join(newN.Path(), op.NewName)

			if err = fs.move(ctx, oldPath, newPath); err != nil {
				return
			}

			cloned := oldN.Clone()
			cloned.Name = op.NewName
			cloned.Entry.Virtual.Inode = fs.Index.Tree().GenerateInode()

			g.AddChild(newN, cloned)

			oldChild.PromiseDel()
			cloned.PromiseAdd()
		})

	if err == nil {
		fs.commit(oldPath, index.ChangeMetaLocal|index.ChangeMetaRemove)
		fs.commit(newPath, index.ChangeMetaLocal|index.ChangeMetaAdd)
	}

	return
}

// RmDir deletes a directory from remote and list of live nodes.
//
// Note: `rm -r` calls Unlink method on each directory entry.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) RmDir(ctx context.Context, op *fuseops.RmDirOp) (err error) {
	var path string
	fs.Index.Tree().DoInode(uint64(op.Parent), func(g node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		child := n.GetChild(op.Name)
		if child == nil || !child.Entry.Virtual.Promise.Exist() {
			err = fuse.ENOENT
			return
		}

		if !child.Entry.File.Mode.IsDir() {
			err = fuse.ENOTDIR
			return
		}

		path = filepath.Join(n.Path(), op.Name)
		abs := filepath.Join(fs.CacheDir, path)
		if err = os.Remove(filepath.Dir(abs)); err != nil && !os.IsNotExist(err) {
			return
		}

		child.PromiseDel()
	})

	if err == nil {
		fs.commit(path, index.ChangeMetaLocal|index.ChangeMetaRemove)
	}

	return
}

// Unlink removes entry from specified parent directory.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) Unlink(ctx context.Context, op *fuseops.UnlinkOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Parent), func(g node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		child := n.GetChild(op.Name)
		if child == nil || !child.Entry.Virtual.Promise.Exist() {
			err = fuse.ENOENT
			return
		}

		err = fs.unlink(n)
	})

	return
}

// ForgetInode removes a file specified by an inode ID if the file was previously
// marked for an unlink.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) ForgetInode(ctx context.Context, op *fuseops.ForgetInodeOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Inode), func(g node.Guard, n *node.Node) {
		if n == nil {
			err = fuse.ENOENT
			return
		}

		if n.Entry.Virtual.Promise&node.EntryPromiseUnlink != 0 {
			err = fs.rm(n)
		}
	})

	return
}

// OpenDir opens a directory, ie. indicates operations are to be done on this
// directory.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) OpenDir(ctx context.Context, op *fuseops.OpenDirOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Inode), func(_ node.Guard, n *node.Node) {
		err = checkDir(n)
	})

	return
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
func (fs *Filesystem) ReadDir(ctx context.Context, op *fuseops.ReadDirOp) (err error) {
	var dirents []*fuseutil.Dirent
	fs.Index.Tree().DoInode(uint64(op.Inode), func(g node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		if offset := int(op.Offset); offset > n.ChildN() {
			err = fuse.EIO
			return
		} else if offset == n.ChildN() {
			return
		}

		i := 0
		n.Children(int(op.Offset), func(child *node.Node) {
			i++
			dirents = append(dirents, &fuseutil.Dirent{
				Offset: op.Offset + fuseops.DirOffset(i),
				Inode:  fuseops.InodeID(child.Entry.Virtual.Inode),
				Name:   child.Name,
				Type:   direntType(n.Entry),
			})
		})
	})

	sum := 0
	// TODO(rjeczalik): we can estimate how many entries to return by
	// looking at op.Dst size.
	for _, dir := range dirents {
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
func (fs *Filesystem) OpenFile(ctx context.Context, op *fuseops.OpenFileOp) (err error) {
	var h fuseops.HandleID
	fs.Index.Tree().DoInode(uint64(op.Inode), func(_ node.Guard, n *node.Node) {
		if n == nil {
			err = fuse.ENOENT
			return
		}

		_, h, err = fs.open(ctx, n)
	})

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
	f, _, err := fs.openHandleInfo(op.Handle)
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
	f, nID, err := fs.openHandleInfo(op.Handle)
	if err != nil {
		return err
	}

	if _, err = f.WriteAt(trimRightNull(op.Data), op.Offset); err != nil {
		return err
	}

	err = f.Sync()
	if fi, e := f.Stat(); e == nil {
		fs.Index.Tree().DoInode(uint64(nID), func(_ node.Guard, n *node.Node) {
			if n == nil {
				return
			}

			n.Entry.File.Size = fi.Size()
		})
	}

	if err == nil {
		fs.commit(fs.rel(f.Name()), index.ChangeMetaLocal|index.ChangeMetaUpdate)
	}

	return nil
}

// SyncFile sends file contents from local to remote.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) SyncFile(ctx context.Context, op *fuseops.SyncFileOp) error {
	f, nID, err := fs.openHandleInfo(op.Handle)
	if err != nil {
		return err
	}

	err = f.Sync()
	if fi, e := f.Stat(); e == nil {
		fs.Index.Tree().DoInode(uint64(nID), func(_ node.Guard, n *node.Node) {
			if n == nil {
				return
			}

			n.Entry.File.Size = fi.Size()
		})
	}

	if err == nil {
		fs.commit(fs.rel(f.Name()), index.ChangeMetaLocal|index.ChangeMetaUpdate)
	}

	return err
}

// FlushFile yields file updates on a locally cached file.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) FlushFile(ctx context.Context, op *fuseops.FlushFileOp) error {
	if op.Handle == 0 {
		return nil
	}

	f, nID, err := fs.openHandleInfo(op.Handle)
	if err != nil {
		return err
	}

	err = f.Sync()
	if fi, e := f.Stat(); e == nil {
		fs.Index.Tree().DoInode(uint64(nID), func(_ node.Guard, n *node.Node) {
			if n == nil {
				return
			}

			n.Entry.File.Size = fi.Size()
		})
	}

	if err == nil {
		fs.commit(fs.rel(f.Name()), index.ChangeMetaLocal|index.ChangeMetaUpdate)
	}

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
		_ = f.File.Close()
	}
	fs.handles = make(map[fuseops.HandleID]HandleInfo)
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
